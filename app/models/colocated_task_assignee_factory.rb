class ColocatedTaskAssigneeFactory < RoundRobinTaskAssigneeFactory
  def initialize(list_of_assignees: Colocated.singleton.non_admins.sort_by(&:id).pluck(:css_id),
                 task_type: ColocatedTask)
    super
  end
end
