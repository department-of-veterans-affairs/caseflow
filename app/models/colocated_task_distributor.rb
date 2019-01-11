class ColocatedTaskDistributor < RoundRobinTaskDistributor
  def initialize(list_of_assignees: Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id),
                 task_class: Task)
    super
  end

  def next_assignee(options = {})
    open_assignee = options.dig(:appeal)
      &.tasks
      &.where&.not(status: Constants.TASK_STATUSES.completed)
      &.find_by(assigned_to: User.where(css_id: list_of_assignees))
      &.assigned_to

    open_assignee || super()
  end
end
