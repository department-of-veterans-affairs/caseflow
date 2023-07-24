# frozen_string_literal: true

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

    hearing_not_scheduled_in_past(open_task.hearing)
  end

  # Ensure hearing associated with AssignHearingDispositionTask is not scheduled in the past
  def hearing_not_scheduled_in_past(hearing)
    hearing.scheduled_for >= Time.zone.now
  end
end
