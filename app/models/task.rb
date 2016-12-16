class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  validate :no_open_tasks_for_appeal, on: :create

  class AlreadyAssignedError < StandardError; end
  class NotAssignedError < StandardError; end
  class AlreadyCompleteError < StandardError; end
  class MustImplementInSubclassError < StandardError; end
  class UserAlreadyHasTaskError < StandardError; end

  COMPLETION_STATUS_MAPPING = {
    completed: 0,
    cancelled: 1,
    expired: 2,
    routed_to_ro: 3
  }.freeze

  REASSIGN_OLD_TASKS = [:EstablishClaim].freeze

  class << self
    def unassigned
      where(user_id: nil)
    end

    def assigned_not_completed
      to_complete.where.not(assigned_at: nil)
    end

    def newest_first(column = :created_at)
      order(column => :desc)
    end

    def oldest_first
      order(created_at: :asc)
    end

    def completed_today
      where(completed_at: DateTime.now.beginning_of_day.utc..DateTime.now.end_of_day.utc)
    end

    def to_complete
      where(completed_at: nil)
    end

    def completed
      where.not(completed_at: nil)
    end

    def to_complete_task_for_appeal(appeal)
      where(completed_at: nil, appeal: appeal)
    end

    def completion_status_code(text)
      COMPLETION_STATUS_MAPPING[text]
    end
  end

  def initial_action
    fail MustImplementInSubclassError
  end

  def before_assign
    # Test hook for testing race conditions
  end

  def assign!(user)
    before_assign
    fail(AlreadyAssignedError) if self.user
    fail(AlreadyStartedError) if started?
    fail(AlreadyCompleteError) if complete?

    # Should this be a constraint in our system?
    fail(UserAlreadyHasTaskError) if user.tasks.to_complete.where(type: type).count > 0

    update!(
      user: user,
      assigned_at: Time.now.utc
    )
    self
  end

  def cancel!(feedback = nil)
    transaction do
      update!(comment: feedback)
      complete_and_recreate!(:cancelled)
    end
  end

  def expire!
    complete_and_recreate!(:expired)
  end

  def complete_and_recreate!(status_code)
    transaction do
      complete!(self.class.completion_status_code(status_code))
      self.class.create!(appeal_id: appeal_id, type: type)
    end
  end

  def start!
    fail(NotAssignedError) unless assigned?
    fail(AlreadyStartedError) if started?
    fail(AlreadyCompleteError) if complete?
    return if started?

    update!(started_at: Time.now.utc)
  end

  def started?
    started_at
  end

  def assigned?
    assigned_at
  end

  def progress_status
    if completed_at
      "Complete"
    elsif started_at
      "In Progress"
    elsif assigned_at
      "Not Started"
    else
      "Unassigned"
    end
  end

  def complete?
    completed_at
  end

  def canceled?
    completion_status === self.class.completion_status_code(:cancelled)
  end

  # completion_status is 0 for success, or non-zero to specify another completed case
  def complete!(status)
    fail(AlreadyCompleteError) if complete?

    update!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  def completion_status_text
    COMPLETION_STATUS_MAPPING.key(completion_status).to_s.titleize
  end

  def no_open_tasks_for_appeal
    if self.class.to_complete_task_for_appeal(appeal).count > 0
      errors.add(:appeal, "Uncompleted task already exists for this appeal")
    end
  end

  def attributes
    super.merge(type: type)
  end

  def to_hash
    serializable_hash(
      include: [:user, appeal: { methods: [:decision_date, :veteran_name] }],
      methods: [:progress_status]
    )
  end
end
