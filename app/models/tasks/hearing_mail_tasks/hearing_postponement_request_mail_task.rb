# frozen_string_literal: true

##
# Task to process a hearing postponement request received via the mail
#
# When this task is created:
#   - It's parent task is set as the RootTask of the associated appeal
#   - The task is assigned to the MailTeam to track how the child was created
#   - A child task of the same name is created and assigned to the HearingAdmin organization
#
# If there is an active ScheduleHearingTask in the appeal's task tree, or there is an open AssignHearingDispositionTask
# whose associated hearing is not scheduled in the past, the following actions are available to a Hearing Admin
#   1. Change task type
#   2. Mark as complete
#   3. Assign to team
#   4. Assign to person
#   5. Cancel task
# Otherwise:
#   1. Change task type
#   2. Cancel task
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

  private

  def active_schedule_hearing_task?
    appeal.tasks.where(type: ScheduleHearingTask.name).active.any?
  end

  def open_assign_hearing_disposition_task?
    # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
    disposition_task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    open_task = appeal.tasks.where(type: disposition_task_names).open.first

    return false unless open_task&.hearing

    hearing_not_scheduled_in_past?(open_task.hearing)
  end

  # Ensure hearing associated with AssignHearingDispositionTask is not scheduled in the past
  def hearing_not_scheduled_in_past?(hearing)
    hearing.scheduled_for >= Time.zone.now
  end
end
