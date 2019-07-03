# frozen_string_literal: true

class OtherColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.other
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
