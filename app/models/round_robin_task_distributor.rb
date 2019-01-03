class RoundRobinTaskDistributor
  def initialize(list_of_assignees:, task_type:)
    @list_of_assignees = list_of_assignees
    @task_type = task_type
  end

  def latest_task
    @task_type.where(assigned_to_type: User.name).order("created_at").last
  end

  def last_assignee_css_id
    latest_task ? latest_task.assigned_to.css_id : nil
  end

  def last_assignee_index
    @list_of_assignees.index(last_assignee_css_id)
  end

  def next_assignee_index
    return 0 unless last_assignee_css_id
    return 0 unless last_assignee_index
    (last_assignee_index + 1) % @list_of_assignees.length
  end

  def next_assignee_css_id
    if @list_of_assignees.blank?
      fail Caseflow::Error::RoundRobinTaskDistributorError, message: "list_of_assignees cannot be empty"
    end

    @list_of_assignees[next_assignee_index]
  end

  def next_assignee
    User.find_by_css_id_or_create_with_default_station_id(next_assignee_css_id)
  end
end
