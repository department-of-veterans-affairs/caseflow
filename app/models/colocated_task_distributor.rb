# frozen_string_literal: true

class ColocatedTaskDistributor < RoundRobinTaskDistributor
  def initialize(assignee_pool: Colocated.singleton.non_admins.sort_by(&:id),
                 task_class: Task)
    super
    @state[:invoker] = "colocated"
  end

  def next_assignee(options = {})
    open_assignee = options[:appeal]
      &.tasks
      &.open
      &.find_by(assigned_to: assignee_pool)
      &.assigned_to

    @state[:appeal_id] = options[:appeal]&.id
    @state[:existing_assignee] = open_assignee&.id
    log_state

    open_assignee || super()
  end
end
