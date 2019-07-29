# frozen_string_literal: true

##
# Task to track when an appeal has been assigned to Privacy Team

class FoiaTask < GenericTask
  def available_actions(user)
    super(user).reject { |action| action == Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h }
  end
end
