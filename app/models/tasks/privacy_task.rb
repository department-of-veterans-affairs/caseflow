# frozen_string_literal: true

##
# Task to track when an appeal has been assigned to Privacy Team

class PrivacyActTask < GenericTask
  def available_actions(user)
    return super if assigned_to != user

    [
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      # Constants.TASK_ACTIONS.RETURN_TO_JUDGE.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def self.create_from_root_task(root_task)
    create!(assigned_to: PrivacyTeam.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end
end
