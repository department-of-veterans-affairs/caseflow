class RoundRobinTaskDistributor
  include ActiveModel::Model

  attr_accessor :assignee_pool, :task_class

  def assignee_users
    User.where(css_id: assignee_pool)
  end

  def latest_task
    task_class.where(assigned_to: assignee_users).max_by(&:created_at)
  end

  def last_assignee_css_id
    latest_task&.assigned_to&.css_id
  end

  def last_assignee_index
    assignee_pool.index(last_assignee_css_id)
  end

  def next_assignee_index
    return 0 unless last_assignee_css_id
    return 0 unless last_assignee_index

    (last_assignee_index + 1) % assignee_pool.length
  end

  def next_assignee_css_id
    if assignee_pool.blank?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_EMPTY_MESSAGE
    end

    assignee_pool[next_assignee_index]
  end

  def next_assignee(_options = {})
    User.find_by_css_id_or_create_with_default_station_id(next_assignee_css_id)
  end
end
