# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  def available_actions_with_conditions(core_actions)
    core_actions = super(core_actions)
    if appeal.is_a?(LegacyAppeal)
      return legacy_schedule_hearing_actions(core_actions)
    end

    core_actions
  end
end
