# frozen_string_literal: true

class PoaClarificationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.poa_clarification
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
