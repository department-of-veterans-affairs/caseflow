# frozen_string_literal: true

class BvaDispatchTaskDistributor < RoundRobinTaskDistributor
  def initialize(assignee_pool: BvaDispatch.singleton.non_admins.sort_by(&:id),
                 task_class: BvaDispatchTask)
    super
  end
end
