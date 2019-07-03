# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
