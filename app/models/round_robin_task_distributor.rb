class RoundRobinTaskDistributor
  include ActiveModel::Model

  validates :task_class, :assignee_pool, presence: true
  validate :assignee_pool_must_contain_only_users

  attr_accessor :assignee_pool, :task_class

  def latest_task
    task_class.where(assigned_to: assignee_pool).max_by(&:created_at)
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
