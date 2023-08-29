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

  # Purpose: When a hearing is postponed through the completion of a NoShowHearingTask, AssignHearingDispositionTask,
  #          or ChangeHearingDispositionTask, cancel any open HearingPostponementRequestMailTasks in that appeal's
  #          task tree, as the HPR mail tasks have become redundant.
  #
  # Params: completed_task - task object of the completed task through which the hearing was postponed
  #         updated_at - datetime when the task was completed
  #
  # Return: The cancelled HPR mail tasks
  def cancel_when_made_redundant(completed_task, updated_at)
    user = ensure_user_can_cancel_task(completed_task)
    params = {
      status: Constants.TASK_STATUSES.cancelled,
      instructions: format_cancellation_reason(completed_task.type, updated_at)
    }
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

  # Purpose: If hearing postponed by a member of HearingAdminTeam, return that user. Otherwise,
  #          in case that hearing in postponed by HearingChangeDispositionJob, return a backup
  #          user with HearingAdmin privileges to pass validation checks in Task#update_from_params
  #
  # Params: completed_task - Task object of task through which heairng was postponed
  def ensure_user_can_cancel_task(completed_task)
    current_user = RequestStore[:current_user]

    return current_user if current_user.in_hearing_admin_team?

    provide_backup_user(completed_task)
  end

  # Purpose: Return user who last updated hearing. If NoShowHearingTask, find hearing by calling #hearing
  #          on parent AssignHearingDispositionTask
  #
  # Params: completed_task - Task object of task through which heairng was postponed
  #
  # Return: User object
  def provide_backup_user(completed_task)
    completed_task&.hearing&.updated_by || completed_task.parent.hearing.updated_by
  end

  # Purpose: Format context to be appended to HPR mail tasks instructions upon task cancellation
  #
  # Params: task_name - string of name of completed task through which hearing was postponed
  #         updated_at - datetime when the task was completed
  #
  # Return: String to be submitted in instructions field of task
  def format_cancellation_reason(task_name, updated_at)
    "##### REASON FOR CANCELLATION:\n" \
    "Hearing postponed when #{task_name} was completed on #{updated_at.strftime('%m/%d/%Y')}"
  end
end
