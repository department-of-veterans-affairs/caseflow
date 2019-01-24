class BvaDispatchTaskDistributor < RoundRobinTaskDistributor
  def initialize(list_of_assignees: BvaDispatch.singleton.users.order(:id).pluck(:css_id),
                 task_class: BvaDispatchTask)
    super
  end
end
