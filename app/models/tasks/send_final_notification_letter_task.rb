# frozen_string_literal: true

class SendFinalNotificationLetterTask < LetterTask
  validates :parent, presence: true

  def available_actions(user)
    if assigned_to.user_has_access?(user) # feature toggle will go here
      SEND_FINAL_NOTIFICATION_LETTER_TASK_ACTIONS
    else
      []
    end
  end

  SEND_FINAL_NOTIFICATION_LETTER_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER.to_h,
    Constants.TASK_ACTIONS.RESEND_FINAL_NOTIFICATION_LETTER.to_h,
    Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_TASK.to_h
  ].freeze
end
