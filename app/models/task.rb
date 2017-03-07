class Task < ActiveRecord::Base
  include AASM

  belongs_to :user
  belongs_to :appeal

  validate :no_open_tasks_for_appeal, on: :create

  class MustImplementInSubclassError < StandardError; end
  class UserAlreadyHasTaskError < StandardError; end

  COMPLETION_STATUS_MAPPING = {
    completed: 0,
    canceled: 1,
    expired: 2,
    routed_to_ro: 3,
    assigned_existing_ep: 4,
    special_issue_emailed: 5,
    special_issue_not_emailed: 6
  }.freeze

  # Use this to define status texts that don't properly titlize
  COMPLETION_STATUS_TEXT_MAPPING = {
    assigned_existing_ep: "Assigned Existing EP"
  }.freeze

  REASSIGN_OLD_TASKS = [:EstablishClaim].freeze

  class << self
    def unassigned
      where(user_id: nil)
    end

    def unprepared
      where(aasm_state: "unprepared")
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

    def completed_today_by_user(user_id)
      where(completed_at: DateTime.now.beginning_of_day.utc..DateTime.now.end_of_day.utc,
            user_id: user_id)
    end

    def to_complete
      where.not(aasm_state: "completed").where.not(aasm_state: "unprepared")
    end

    def completed
      where(aasm_state: "completed")
    end

    def to_complete_task_for_appeal(appeal)
      to_complete.where(appeal: appeal)
    end

    def completion_status_code(text)
      COMPLETION_STATUS_MAPPING[text]
    end

    def tasks_completed_by_users(tasks)
      tasks.each_with_object({}) do |task, user_numbers|
        user_numbers[task.user.full_name] = (user_numbers[task.user.full_name] || 0) + 1
      end
    end
  end

  aasm do
    state :unprepared, initial: true
    state :unassigned, :assigned, :started, :reviewed, :completed

    ## The 'unprepared' state is being used for establish claim tasks to designate
    #  tasks attached to appeals that do not have decision documents. Tasks that are
    #  in this state cannot be assigned to users. All tasks are in this state
    #  immediately after creation.
    event :prepare do
      transitions from: :unprepared, to: :unassigned
    end

    event :assign do
      transitions from: :unassigned, to: :assigned, after: proc { |*args| assign_user(*args) }
    end

    event :start do
      transitions from: :assigned, to: :started, after: :start_time
    end

    # The 'review' state is being used for establish claim tasks to designate that an
    # external action has been completed, and we want to the user to perform one more
    # action or review the external action. In the case of establish claim we're letting
    # them add a note to VBMS
    event :review do
      transitions from: :started, to: :reviewed, after: proc { |*args| save_outgoing_reference(*args) }
    end

    event :complete do
      transitions from: :reviewed, to: :completed, after: proc { |*args| save_completion_status(*args) }
      transitions from: :started, to: :completed,
                  guard: proc { |*args| no_review_completion_status(*args) },
                  after: proc { |*args| save_completion_status(*args) }
    end
  end

  def before_assign
    # Test hook for testing race conditions
  end

  def assign_user(user)
    fail(UserAlreadyHasTaskError) if user.tasks.to_complete.where(type: type).count > 0
    update!(
      user: user,
      assigned_at: Time.now.utc
    )
  end

  def start_time
    update!(started_at: Time.now.utc)
  end

  def prepare_with_decision!
    return false if appeal.decisions.empty?

    appeal.decisions.each(&:fetch_and_cache_document_from_vbms)

    prepare!
  end

  def cancel!(feedback = nil)
    transaction do
      update!(comment: feedback)
      review! if may_review?
      complete!(:completed, status: self.class.completion_status_code(:canceled))
    end
  end

  def expire!
    Task.transaction do
      review! if may_review?
      complete_and_recreate!(:expired)
    end
  end

  def assign_existing_end_product!(end_product_id)
    Task.transaction do
      review!(outgoing_reference_id: end_product_id) if may_review?
      complete!(:completed, status: self.class.completion_status_code(:assigned_existing_ep))
    end
  end

  def complete_and_recreate!(status_code)
    transaction do
      complete!(:completed, status: self.class.completion_status_code(status_code))
      self.class.create!(appeal_id: appeal_id, type: type)
    end
  end

  def progress_status
    if completed_at
      "Completed"
    elsif started_at
      "In Progress"
    elsif assigned_at
      "Not Started"
    else
      "Unassigned"
    end
  end

  def canceled?
    completion_status == self.class.completion_status_code(:canceled)
  end

  def assigned_existing_ep?
    completion_status == self.class.completion_status_code(:assigned_existing_ep)
  end

  def special_issue_emailed?
    completion_status == self.class.completion_status_code(:special_issue_emailed)
  end

  def special_issue_not_emailed?
    completion_status == self.class.completion_status_code(:special_issue_not_emailed)
  end

  def days_since_creation
    (Time.zone.now - created_at).to_i / 1.day
  end

  # completion_status is 0 for success, or non-zero to specify another completed case
  def save_completion_status(status:)
    update!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  def no_review_completion_status(status:)
    [
      self.class.completion_status_code(:special_issue_emailed),
      self.class.completion_status_code(:special_issue_not_emailed)
    ].include? status
  end

  def save_outgoing_reference(outgoing_reference_id: nil)
    update!(
      outgoing_reference_id: outgoing_reference_id
    )
  end

  def completion_status_text
    status = COMPLETION_STATUS_MAPPING.key(completion_status)
    COMPLETION_STATUS_TEXT_MAPPING[status] ||
      status.to_s.titleize
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
      include: [:user, appeal: { methods:
       [:serialized_decision_date,
        :veteran_name,
        :decision_type,
        :vbms_id] }],
      methods: [:progress_status, :days_since_creation, :completion_status_text]
    )
  end

  def to_hash_with_bgs_call
    serializable_hash(
      include: [:user, appeal: {
        include:
          [decisions: { methods: :received_at }],
        methods:
        [:serialized_decision_date,
         :decisions_hash,
         :disposition,
         :veteran_name,
         :decision_type,
         :station_key,
         :regional_office_key,
         :non_canceled_end_products_within_30_days,
         :pending_eps,
         :issues,
         :to_hash] }],
      methods: [:progress_status, :aasm_state]
    )
  end
end
