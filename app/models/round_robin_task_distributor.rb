# frozen_string_literal: true

class RoundRobinTaskDistributor
  include ActiveModel::Model

  validates :task_class, :assignee_pool, presence: true
  validate :assignee_pool_must_contain_only_users

  attr_accessor :assignee_pool, :task_class

  def initialize(assignee_pool:, task_class:)
    @assignee_pool = assignee_pool.select(&:active?)
    @task_class = task_class
    @state = {
      class: self.class.name,
      invoker: "round_robin",
      task_class: @task_class.name,
      assignee_pool: @assignee_pool.pluck(:id)
    }
  end

  def latest_task
    # Use id as a proxy for created_at since the id field is already indexed.
    # Request .visible_in_queue_table_view to avoid TimedHoldTask or similar tasks
    latest = task_class
      .visible_in_queue_table_view
      .where(assigned_to: assignee_pool)
      .order(id: :desc)
      .first
    @state[:latest_task_id] = latest&.id
    latest
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
    curr_last_assignee = last_assignee
    @state[:last_assignee_id] = curr_last_assignee&.id

    (last_assignee_index + 1) % assignee_pool.length
  end

  def next_assignee(options = {})
    unless valid?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: errors.full_messages.join(", ")
    end

    next_index = next_assignee_index
    @state[:next_index] = next_index ? assignee_pool[next_index].id : nil
    @state[:appeal_id] = options[:appeal_id] || "no appeal_id"
    log_state
    assignee_pool[next_index]
  end

  private

  def assignee_pool_must_contain_only_users
    unless assignee_pool.all? { |a| a.is_a?(User) }
      errors.add(:assignee_pool, COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_USERS_ONLY_MESSAGE)
    end
  end

  # Output a semicolon separated list of debugging info to the logs
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
  def log_state
    elements = [:class, :invoker, :appeal_id, :task_class, :task_id, :latest_task_id, :last_assignee_id, :next_index,
                :existing_assignee, :assignee_pool]
    log_string = "RRDTracking;" + elements.map { |key| "#{key}: #{@state[key]}" }.join("; ")
    puts log_string
    # pp @state
    Rails.logger.info(log_string)
  end
end
