# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  def available_actions(core_actions)
    core_actions = super(core_actions)
    appeal.is_a?(LegacyAppeal) ? legacy_schedule_hearing_actions(core_actions) : core_actions
  end

  private

  def legacy_schedule_hearing_actions(actions)
    task_actions = Constants.TASK_ACTIONS
    actions = actions.reject { |action| action[:label] == task_actions.ASSIGN_TO_PRIVACY_TEAM.to_h[:label] }
    actions.unshift(task_actions.SCHEDULE_HEARING_SEND_TO_TEAM.to_h)
    actions
  end

  def vacols_location
    # Return to attorney if the task is cancelled. For instance, if the VLJ support staff sees that the hearing was
    # actually held.
    return assigned_by.vacols_uniq_id if children.all? { |child| child.status == Constants.TASK_STATUSES.cancelled }

    # Schedule hearing with a task (instead of changing Location in VACOLS, the old way)
    ScheduleHearingTask.create!(appeal: appeal, parent: appeal.root_task)
    LegacyAppeal::LOCATION_CODES[:caseflow]
  end
end
