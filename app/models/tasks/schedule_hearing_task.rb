# frozen_string_literal: true

##
# Task to schedule a hearing for a veteran making a claim.
#
# When this task is created, HearingTask is created as the parent task in the appeal tree.
#
# For AMA appeals, task is created by the intake process for any appeal electing to have a hearing.
# For Legacy appeals, Geomatching is responsible for finding all appeals in VACOLS ready to be scheduled
# and creating a ScheduleHearingTask for each of them.
#
# A coordinator can block this task by creating a HearingAdminActionTask for some reasons listed
# here: https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#2-schedule-veteran
#
# This task also allows coordinators to withdraw unscheduled hearings (i.e cancel this task)
# For AMA, this creates an EvidenceSubmissionWindowTask as child of parent HearingTask and for legacy appeal,
# vacols field `bfha` and `bfhr` are updated.
#
# If cancelled, the parent HearingTask is automatically closed. If this task is the last closed task for the
# hearing subtree and there are no more open HearingTasks, the logic in HearingTask#when_child_task_completed
# properly handles routing or creating ihp task.
#
# If completed, an AssignHearingDispositionTask is created as a child of HearingTask.
##
class ScheduleHearingTask < Task
  include CavcAdminActionConcern

  before_validation :set_assignee
  before_create :create_parent_hearing_task
  delegate :hearing, to: :parent, allow_nil: true

  # error to capture any instances where expect the parent HearingTask to have no
  # open children tasks but it does
  class HearingTaskHasOpenChildren < StandardError; end

  def self.label
    "Schedule hearing"
  end

  def default_instructions
    [COPY::SCHEDULE_HEARING_TASK_DEFAULT_INSTRUCTIONS]
  end

  def create_parent_hearing_task
    if parent.type != HearingTask.name
      self.parent = HearingTask.create(appeal: appeal, parent: parent)
    end
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      # Either change the hearing request type or schedule/cancel the hearing
      if params.dig(:business_payloads, :values, :changed_hearing_request_type).present?
        change_hearing_request_type(params, current_user)
      else
        created_tasks = create_schedule_hearing_tasks(params)

        # super returns [self]
        super(params, current_user) + created_tasks.compact
      end
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    hearing_task = most_recent_closed_hearing_task_on_appeal

    if hearing_task&.hearing&.disposition.blank?
      fail Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
    end

    multi_transaction do
      # cancel the old HearingTask and create a new one associated with the same hearing
      # NOTE: We need to first create new hearing task so there is at least one open hearing task for
      # when_child_task_completed in HearingTask to prevent triggering of location change for legacy appeals
      # with update below
      new_hearing_task = hearing_task.cancel_and_recreate

      # cancel my children, myself, and possibly my hearing task ancestor
      # NOTE: possibly because cancellation depends on whether or not the tasks are assigned to BVA org
      # and all the children tasks of HearingTask have been cancelled
      cancel_task_and_child_subtasks

      parent = ancestor_task_of_type(HearingTask)

      cancel_parent_task(parent) if parent

      # create the association for new hearing task
      HearingTaskAssociation.create!(hearing: hearing_task.hearing, hearing_task: new_hearing_task)

      # create a ChangeHearingDispositionTask on the new HearingTask
      new_hearing_task.create_change_hearing_disposition_task(instructions)
    end
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || HearingsManagement.singleton.user_has_access?(user)
      schedule_hearing_action = if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing, user: user)
                                  Constants.TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE
                                else
                                  Constants.TASK_ACTIONS.SCHEDULE_VETERAN
                                end
      return [
        schedule_hearing_action.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h
      ] | hearing_admin_actions
    end

    hearing_admin_actions
  end

  # Override the available user actions to inject change hearing request type tasks
  def available_hearing_user_actions(user)
    # Capture the parent user actions
    parent_admin_actions = super(user)

    # Apply the change hearing request type tasks if allowed
    if user.can_change_hearing_request_type?
      return parent_admin_actions | change_hearing_request_type_actions
    end

    # Default return the parent user actions
    parent_admin_actions
  end

  private

  # Method to return the user actions for changing the hearing request type
  def change_hearing_request_type_actions
    case appeal.current_hearing_request_type
    when :central, :central_office
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.to_h,
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    when :video, nil
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_CENTRAL.to_h,
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    when :virtual
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.to_h,
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_CENTRAL.to_h
      ]
    else
      []
    end
  end

  # Method to create the appropriate schedule hearing tasks based on the status
  def create_schedule_hearing_tasks(params)
    # Instantiate the tasks to create for the schedule hearing task
    created_tasks = []

    # Check if we are completing the schedule hearing task
    if params[:status] == Constants.TASK_STATUSES.completed
      # Extract the schedule hearing task values and create a hearing from them
      task_values = params.delete(:business_payloads)[:values]
      hearing = create_hearing(task_values)

      # Create the virtual hearing if the attributes have been passed
      if task_values[:virtual_hearing_attributes].present?
        @alerts = VirtualHearings::ConvertToVirtualHearingService
          .convert_hearing_to_virtual(hearing, task_values[:virtual_hearing_attributes])
      elsif task_values[:email_recipients].present?
        create_email_recipients(hearing, task_values[:email_recipients])
      end

      # Create and assign the hearing now that it has been scheduled
      created_tasks << AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, parent, hearing)

    # The only other option is to cancel the schedule hearing task
    elsif params[:status] == Constants.TASK_STATUSES.cancelled
      # If we are cancelling the schedule hearing task, we need to withdraw the request
      created_tasks << withdraw_hearing(parent)
    end

    # Return the created tasks
    created_tasks
  end

  # Method to change the hearing request type on an appeal
  def change_hearing_request_type(params, current_user)
    change_hearing_request_type_task = ChangeHearingRequestTypeTask.create!(
      appeal: appeal,
      assigned_to: current_user,
      parent: self
    )

    # Call the child method so that we follow that workflow when changing the hearing request type
    change_hearing_request_type_task.update_from_params(params, current_user)
  end

  def cancel_parent_task(parent)
    # if parent HearingTask does not have any open children tasks, cancel it
    if parent.children.open.empty?
      parent.update!(status: Constants.TASK_STATUSES.cancelled, closed_at: Time.zone.now)
    else # otherwise don't cancel it and capture error in sentry
      Raven.capture_exception(
        HearingTaskHasOpenChildren.new(
          "Hearing Task with id #{parent&.id} could not be cancelled because it has open children tasks."
        )
      )
    end
  end

  def create_hearing(task_values)
    HearingRepository.slot_new_hearing(
      {
        hearing_day_id: task_values[:hearing_day_id],
        appeal: appeal,
        hearing_location_attrs: task_values[:hearing_location]&.to_hash,
        scheduled_time_string: task_values[:scheduled_time_string],
        notes: task_values[:notes]
      },
      override_full_hearing_day_validation: task_values[:override_full_hearing_day_validation]
    )
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end

  def create_email_recipients(hearing, recipient)
    if recipient["appellant_email"].present?
      hearing.create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: recipient["appellant_email"],
        timezone: recipient["appellant_tz"]
      )
    end

    if recipient["representative_email"].present?
      hearing.create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: recipient["representative_email"],
        timezone: recipient["representative_tz"]
      )
    end
  end
end
