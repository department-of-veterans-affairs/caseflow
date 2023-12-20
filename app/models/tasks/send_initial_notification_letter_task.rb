# frozen_string_literal: true

class SendInitialNotificationLetterTask < LetterTask
  validates :parent, presence: true

  def label
    "Send Initial Notification Letter"
  end

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    task_actions = Array.new(SEND_INITIAL_NOTIFICATION_LETTER_TASK_ACTIONS)

    task_actions
  end

  SEND_INITIAL_NOTIFICATION_LETTER_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.to_h,
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL.to_h,
    Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_INITIAL_LETTER_TASK.to_h
  ].freeze
end
