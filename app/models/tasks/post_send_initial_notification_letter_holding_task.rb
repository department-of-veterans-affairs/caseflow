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
    Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_POST_INITIAL_LETTER_TASK.to_h,
    Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER.to_h,
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER.to_h,
  ].freeze

  # overrides for timed_hold_task methods
  def self.hide_from_queue_table_view
    false
  end

  def hide_from_case_timeline
    false
  end

  def hide_from_task_snapshot
    false
  end

end
