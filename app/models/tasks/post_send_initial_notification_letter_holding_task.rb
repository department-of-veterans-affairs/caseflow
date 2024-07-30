# frozen_string_literal: true

class PostSendInitialNotificationLetterHoldingTask < LetterTask
  include TimeableTask

  validates :parent, presence: true, on: :create

  def initialize(args)
    @end_date = args&.fetch(:end_date, nil)
    super(args&.except(:end_date))
  end

  def label
    "Post-Send Initial Notification Letter Holding Period"
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
    Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING.to_h,
    Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING.to_h
  ].freeze

  def when_timer_ends
    update!(status: :completed) if open?
    SendFinalNotificationLetterTaskFactory.new(self).create_send_final_notification_letter_tasks
  end

  # Function to set the end time for the related TaskTimer when this class is instantiated.
  def timer_ends_at
    return @end_date if @end_date

    # Check for last existing associated TaskTimer
    task_timer = TaskTimer.find_by(task: self)
    return task_timer.submitted_at if task_timer
  end
end
