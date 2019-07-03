# frozen_string_literal: true

class HearingClarificationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.hearing_clarification
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
