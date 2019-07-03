# frozen_string_literal: true

class NewRepArgumentsColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.new_rep_arguments
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
