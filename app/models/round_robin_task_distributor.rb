# frozen_string_literal: true

class RoundRobinTaskDistributor
  include ActiveModel::Model

  validates :task_class, :assignee_pool, presence: true
  validate :assignee_pool_must_contain_only_users

  attr_accessor :assignee_pool, :task_class

  def initialize(assignee_pool:, task_class:)
    @assignee_pool = assignee_pool.select(&:active?)
    @task_class = task_class
  end

  def latest_task
    # Use id as a proxy for created_at since the id field is already indexed.
    # Request .visible_in_queue_table_view to avoid TimedHoldTask or similar tasks
    task_class
      .visible_in_queue_table_view
      .where(assigned_to: assignee_pool)
      .order(id: :desc)
      .first
  end

  def last_assignee
    latest_task&.assigned_to
  end

  def last_assignee_index
    assignee_pool.index(last_assignee)
  end

  def next_assignee_index
    return 0 unless last_assignee
    return 0 unless last_assignee_index

    (last_assignee_index + 1) % assignee_pool.length
  end

  def next_assignee(options = {})
    unless valid?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: errors.full_messages.join(", ")
    end

    next_index = next_assignee_index
    log_state(invoker: "round_robin", next_index: next_index, appeal: options.dig(:appeal))
    assignee_pool[next_index]
  end

  private

  def assignee_pool_must_contain_only_users
    unless assignee_pool.all? { |a| a.is_a?(User) }
      errors.add(:assignee_pool, COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_USERS_ONLY_MESSAGE)
    end
  end

  # Output a colon seperated list of debugging info to the logs
  #
  # Class running this
  # Which RR next_assignee called this
  # appeal (not always available)
  # Round Robin Task type being considered
  # Round Robin - task analyzed for last assignee
  # Round Robin - found previous assignee
  # Round Robin - calculated next assignee (if using index)
  # Round Robin - existing assignee for this appeal
  # Round Robin - assignee pool considered
  def log_state(invoker:, next_index: nil, existing_assignee: nil, appeal:)
    log_string = "RRDTracking; "
    log_string += "#{self.class.name}; "
    log_string += "#{invoker}; "
    log_string += "#{appeal ? appeal.id : "not provided"}; "
    log_string += "#{task_class}; "
    log_string += "#{latest_task&.id}; "
    log_string += "#{last_assignee&.id}; "
    log_string += "#{next_index ? assignee_pool[next_index].id : nil}; "
    log_string += "#{existing_assignee}; "
    log_string += "#{assignee_pool.pluck(:id)}; "
    Rails.logger.info(log_string)
  end
end
