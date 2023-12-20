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

  def next_assignee(_options = {})
    unless valid?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: errors.full_messages.join(", ")
    end

    assignee_pool[next_assignee_index]
  end

  private

  def assignee_pool_must_contain_only_users
    unless assignee_pool.all? { |a| a.is_a?(User) }
      errors.add(:assignee_pool, COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_USERS_ONLY_MESSAGE)
    end
  end
end
