# frozen_string_literal: true

class ArnesonColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.arneson
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
