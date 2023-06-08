# frozen_string_literal: true

class HearingWithdrawalRequestMailTask < HearingRequestMailTask
  class << self
    def label
      "Hearing withdrawal request"
    end

    # Only users who are members of orgs where
    #
    #   def users_can_create_mail_task?
    #     true
    #   end
    #
    # can create mail tasks. Those orgs are the same 4 listed in the AC.
    #
    # This method is only being overridden so that HearingRequestMailTask
    # doesn't pop up in the dropdown.
    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS_FOR_ACTIVE_HEARING = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    # Mark as complete and withdraw hearing
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  DEFAULT_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(_user)
    hearing_is_active? ? TASK_ACTIONS_FOR_ACTIVE_HEARING : DEFAULT_TASK_ACTIONS
  end

  private

  # IF there is an active Schedule hearing task
  # OR (there is an active Select hearing disposition task AND its hearing date has not passed)
  def hearing_is_active?
    active_tasks = appeal.tasks.active

    active_tasks.any? { |task| task.is_a?(ScheduleHearingTask) || hearing_pending?(task) }
  end

  def hearing_pending?(task)
    task.is_a?(AssignHearingDispositionTask) && !task.hearing.scheduled_for_past?
  end
end
