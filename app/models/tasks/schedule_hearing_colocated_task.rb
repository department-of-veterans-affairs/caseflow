# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
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

  private

  def vacols_location
    # Return to attorney if the task is cancelled. For instance, if HearingsManagement sees that the hearing was
    # actually held.
    if (children.present? && children.all? { |child| child.status == Constants.TASK_STATUSES.cancelled }) ||
       status == Constants.TASK_STATUSES.cancelled
      return assigned_by.vacols_uniq_id
    end

    # Schedule hearing with a task (instead of changing Location in VACOLS, the old way)
    ScheduleHearingTask.create!(appeal: appeal, parent: appeal.root_task)
    LegacyAppeal::LOCATION_CODES[:caseflow]
  end
end
