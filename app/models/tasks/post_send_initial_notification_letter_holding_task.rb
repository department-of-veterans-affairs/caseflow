class PostSendInitialNotificationLetterHoldingTask  < TimedHoldTask
  include TimeableTask

  validates :parent, presence: true, on: :create
  validates :days_on_hold, presence: true, inclusion: { in: 45..364 }, on: :create
  attr_accessor :days_on_hold

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
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_CC.to_h,
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

  def self.create_from_parent(task, days_on_hold:, assigned_by: nil, instructions: nil)
    multi_transaction do
      if task.is_a?(Task)
        task.update_with_instructions(instructions: instructions)
      end
      psi = create!(
        appeal: task.appeal,
        assigned_by: assigned_by,
        assigned_to: Organization.find_by_url("clerk-of-the-board"),
        parent: task,
        days_on_hold: days_on_hold&.to_i,
        instructions: instructions
      )
      task.update!(status: Constants.TASK_STATUSES.on_hold)
    end
  end

  def when_timer_ends
    update!(status: :completed) if open?
  end

  # Function to set the end time for the related TaskTimer when this class is instantiated.
  def timer_ends_at
    created_at + days_on_hold.days
  end
end
