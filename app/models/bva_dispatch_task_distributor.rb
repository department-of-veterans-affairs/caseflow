class BvaDispatchTaskDistributor < RoundRobinTaskDistributor
  def initialize(assignee_pool: BvaDispatch.singleton.users.order(:id).pluck(:css_id),
                 task_class: BvaDispatchTask)
    super
  end
end
