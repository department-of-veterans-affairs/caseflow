# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  def self.default_assignee
    HearingsManagement.singleton
  end

  def available_actions_with_conditions(core_actions)
    core_actions = super(core_actions)
    appeal.is_a?(LegacyAppeal) ? legacy_schedule_hearing_actions(core_actions) : core_actions
  end
end
