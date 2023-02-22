class PostSendInitialNotificationLetterHoldingTask < LetterTask
  include TimeableTask

  validates :parent, presence: true, on: :create

  def initialize(args)
    @end_date = args&.fetch(:end_date, nil)
    super(args&.except(:end_date))
  end

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
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER.to_h
  ].freeze

  def when_timer_ends
    update!(status: :completed) if open?
  end

  # Function to set the end time for the related TaskTimer when this class is instantiated.
  def timer_ends_at
    return @end_date if @end_date
    # Check for last existing associated TaskTimer
    task_timer = TaskTimer.find_by(task: self)
    return task_timer.submitted_at if task_timer
  end

  def days_on_hold
    # if closed out, set the time to be the difference between created_at and closed_at
    # otherwise, calculate from now if the timer is still going
    if !closed_at.nil?
      (closed_at - created_at).to_i / 1.day
    else
      (Time.zone.now - created_at).to_i / 1.day
    end
  end

  # created_at offset by 1 day to compensate for day difference rounding down.
  def max_hold_day_period
    (timer_ends_at - created_at.prev_day).to_i / 1.day
  end
end
