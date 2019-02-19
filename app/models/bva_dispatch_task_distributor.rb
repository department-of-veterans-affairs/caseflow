class BvaDispatchTaskDistributor < RoundRobinTaskDistributor
  def initialize(assignee_pool: BvaDispatch.singleton.users.order(:id),
                 task_class: BvaDispatchTask)
    super
  end
end
