# frozen_string_literal: true

class IhpColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.ihp
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
