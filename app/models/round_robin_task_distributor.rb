class RoundRobinTaskDistributor
  include ActiveModel::Model

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
    if assignee_pool.blank?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_EMPTY_MESSAGE
    end

    assignee_pool[next_assignee_index]
  end
end
