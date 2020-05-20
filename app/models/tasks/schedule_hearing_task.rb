# frozen_string_literal: true

##
# Task to schedule a hearing for a veteran making a claim.
# Created by the intake process for any appeal electing to have a hearing.
# Once completed, an AssignHearingDispositionTask is created.

class ScheduleHearingTask < Task
  before_validation :set_assignee
  before_create :create_parent_hearing_task

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

        hearing = HearingRepository.slot_new_hearing(
          task_values[:hearing_day_id],
          appeal: appeal,
          hearing_location_attrs: task_values[:hearing_location]&.to_hash,
          scheduled_time_string: task_values[:scheduled_time_string],
          override_full_hearing_day_validation: task_values[:override_full_hearing_day_validation]
        )
        AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, parent, hearing)
      elsif params[:status] == Constants.TASK_STATUSES.cancelled
        withdraw_hearing
      end

      super(params, current_user)
    end
  end

  def create_change_hearing_disposition_task(instructions = nil)
    hearing_task = most_recent_closed_hearing_task_on_appeal

    if hearing_task&.hearing&.disposition.blank?
      fail Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
    end

    multi_transaction do
      # cancel my children, myself, and my hearing task ancestor
      children.open.update_all(status: Constants.TASK_STATUSES.cancelled, closed_at: Time.zone.now)
      update!(status: Constants.TASK_STATUSES.cancelled, closed_at: Time.zone.now)
      ancestor_task_of_type(HearingTask)&.update!(
        status: Constants.TASK_STATUSES.cancelled,
        closed_at: Time.zone.now
      )

      # cancel the old HearingTask and create a new one associated with the same hearing
      new_hearing_task = hearing_task.cancel_and_recreate
      HearingTaskAssociation.create!(hearing: hearing_task.hearing, hearing_task: new_hearing_task)

      # create a ChangeHearingDispositionTask on the new HearingTask
      new_hearing_task.create_change_hearing_disposition_task(instructions)
    end
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || HearingsManagement.singleton.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h,
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.WITHDRAW_HEARING.to_h
      ] | hearing_admin_actions
    end

    hearing_admin_actions
  end

  private

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
