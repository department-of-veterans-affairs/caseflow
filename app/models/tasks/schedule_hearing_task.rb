# frozen_string_literal: true

##
# Task to schedule a hearing for a veteran making a claim.
#
# When this task is created, HearingTask is created as the parent task in the appeal tree.
#
# For AMA appeals, task is created by the intake process for any appeal electing to have a hearing.
# For Legacy appeals, Geomatching is resposnible for finding all appeals in VACOLS ready to be scheduled
# and creating a ScheduleHearingTask for each of them.
#
# A coordinator can block this task by creating a HearingAdminActionTask for some reasons listed
# here: https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#2-schedule-veteran
#
# This task also allows coordinators to withdraw hearings. For AMA, this creates an EvidenceSubmissionWindowTask
# and for legacy this moves the appeal to case storage. If the hearing request is withdrawn before the hearing
# was scheduled, the ScheduleHearingTask is cancelled and the HearingTask is automatically closed.
#
# Once completed, an AssignHearingDispositionTask is created as a child of HearingTask.

class ScheduleHearingTask < Task
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
      if params[:status] == Constants.TASK_STATUSES.completed
        task_values = params.delete(:business_payloads)[:values]

        multi_transaction do
          hearing = create_hearing(task_values)

          if task_values[:virtual_hearing_attributes].present?
            @alerts = VirtualHearings::ConvertToVirtualHearingService
              .convert_hearing_to_virtual(hearing, task_values[:virtual_hearing_attributes])
          end

          AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, parent, hearing)
        end
      elsif params[:status] == Constants.TASK_STATUSES.cancelled
        withdraw_hearing
      end

      super(params, current_user) # returns [self]
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

  private

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
      task_values[:hearing_day_id],
      appeal: appeal,
      hearing_location_attrs: task_values[:hearing_location]&.to_hash,
      scheduled_time_string: task_values[:scheduled_time_string],
      override_full_hearing_day_validation: task_values[:override_full_hearing_day_validation]
    )
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end

  def withdraw_hearing
    if appeal.is_a?(LegacyAppeal)
      location = if appeal.representatives.empty?
                   LegacyAppeal::LOCATION_CODES[:case_storage]
                 else
                   LegacyAppeal::LOCATION_CODES[:service_organization]
                 end

      AppealRepository.withdraw_hearing!(appeal)
      AppealRepository.update_location!(appeal, location)
    else
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end
  end
end
