# frozen_string_literal: true

##
# Task to track when a Freedom of Information Act task has been assigned to Privacy Team

class FoiaTask < Task
  def available_actions(user)
    super(user).reject { |action| action == Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h }
  end
end
