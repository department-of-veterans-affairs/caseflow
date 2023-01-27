class PostSendInitialNotificationLetterHoldingTask  < TimedHoldTask
  include TimeableTask

  validates :parent, presence: true, on: :create

  def available_actions(user)
    if assigned_to.user_has_access?(user) &&
      FeatureToggle.enabled?(:cc_appeal_workflow)
      POST_SEND_INITIAL_NOTIFICATION_LETTER_HOLDING_TASK_ACTIONS
    else
      []
    end
  end

  POST_SEND_INITIAL_NOTIFICATION_LETTER_HOLDING_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_TASK.to_h,
    Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER.to_h,
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_CC.to_h,
  ].freeze

end
