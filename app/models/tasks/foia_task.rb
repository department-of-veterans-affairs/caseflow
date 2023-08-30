# frozen_string_literal: true

##
# Task to track when a Freedom of Information Act task has been assigned to Privacy Team

class FoiaTask < Task
  def available_actions(user)
    super(user).reject { |action| action == Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h }
  end

  ## Tag to determine if this task is considered a blocking task for Legacy Appeal Distribution
  def legacy_blocking
    true
  end
end
