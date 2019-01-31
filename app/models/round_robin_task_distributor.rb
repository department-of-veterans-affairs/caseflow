class RoundRobinTaskDistributor
  include ActiveModel::Model

  attr_accessor :list_of_assignees, :task_class

  def assignee_users
    User.where(css_id: list_of_assignees)
  end

  def latest_task
    task_class.where(assigned_to: assignee_users).max_by(&:created_at)
  end

  def last_assignee_css_id
    latest_task&.assigned_to&.css_id
  end

  def last_assignee_index
    list_of_assignees.index(last_assignee_css_id)
  end

  def next_assignee_index
    return 0 unless last_assignee_css_id
    return 0 unless last_assignee_index

    (last_assignee_index + 1) % list_of_assignees.length
  end

  def next_assignee_css_id
    if list_of_assignees.blank?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: "list_of_assignees cannot be empty"
    end

    list_of_assignees[next_assignee_index]
  end

  def next_assignee(_options = {})
    User.find_by_css_id_or_create_with_default_station_id(next_assignee_css_id)
  end
end
