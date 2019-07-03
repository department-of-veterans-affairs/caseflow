# frozen_string_literal: true

class AojColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.aoj
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
