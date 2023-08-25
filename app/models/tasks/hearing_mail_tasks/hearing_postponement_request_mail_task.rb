# frozen_string_literal: true

##
# Task to process a hearing postponement request received via the mail
#
# When this task is created:
#   - It's parent task is set as the RootTask of the associated appeal
#   - The task is assigned to the MailTeam to track where the request originated
#   - A child task of the same name is created and assigned to the HearingAdmin organization
##
class HearingPostponementRequestMailTask < HearingRequestMailTask
  class << self
    def label
      COPY::HEARING_POSTPONEMENT_REQUEST_MAIL_TASK_LABEL
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(user)
    return [] unless user.in_hearing_admin_team?

    if active_schedule_hearing_task? || open_assign_hearing_disposition_task?
      TASK_ACTIONS
    else
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
  end

  def cancel_when_made_redundant(completed_task, updated_at)
    user = ensure_user_can_cancel_task(completed_task.hearing.updated_by)
    params = build_redundant_task_params(completed_task.type, updated_at)
    update_from_params(params, user)
  end

  private

  def active_schedule_hearing_task?
    appeal.tasks.where(type: ScheduleHearingTask.name).active.any?
  end

  def open_assign_hearing_disposition_task?
    # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
    disposition_task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    open_task = appeal.tasks.where(type: disposition_task_names).open.first

    return false unless open_task&.hearing

    # Ensure hearing associated with AssignHearingDispositionTask is not scheduled in the past
    !open_task.hearing.scheduled_for_past?
  end

  def build_redundant_task_params(task_name, updated_at)
    {
      status: Constants.TASK_STATUSES.cancelled,
      instructions: format_cancellation_reason(task_name, updated_at)
    }
  end

  def format_cancellation_reason(task_name, updated_at)
    "##### REASON FOR CANCELLATION:\n" \
    "Hearing postponed when #{task_name} was completed on #{updated_at.strftime('%m/%d/%Y')}"
  end

  def ensure_user_can_cancel_task(backup_user)
    RequestStore[:current_user].in_hearing_admin_team? ? Requestore[:current_user] : backup_user
  end
end
