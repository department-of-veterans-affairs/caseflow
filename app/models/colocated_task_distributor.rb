# frozen_string_literal: true

class ColocatedTaskDistributorrr < RoundRobinTaskDistributor
  def initialize(assignee_pool: Colocated.singleton.non_admins.sort_by(&:id),
                 task_class: Task)
    super
  end

  def next_assignee(_options = {})
    nil
  end
end
