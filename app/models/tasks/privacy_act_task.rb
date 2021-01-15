# frozen_string_literal: true

##
# Task to track when an appeal has been assigned to Privacy Team

class PrivacyActTask < Task
  include CavcAdminActionConcern

  def available_actions(user)
    return [] unless user

    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    if task_is_assigned_to_user_within_organization?(user)
      return [Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    []
  end
end
