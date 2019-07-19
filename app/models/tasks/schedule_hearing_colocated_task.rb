# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  after_update :create_schedule_hearing_task

  def self.label
    "Confirm #{Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing}"
  end

  def self.default_assignee
    HearingsManagement.singleton
  end

  def available_actions(user)
    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_HEARING_SEND_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    []
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    false
  end

  def hide_from_queue_table_view
    false
  end

  def create_schedule_hearing_task
    if saved_change_to_status? && status == Constants.TASK_STATUSES.completed
      ScheduleHearingTask.create!(appeal: appeal, parent: appeal.root_task)
    end
  end
end
