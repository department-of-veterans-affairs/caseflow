# frozen_string_literal: true

class AppealsWithNoTasksOrAllTasksOnHoldQuery
  def call
    [stuck_appeals, appeals_with_zero_tasks, dispatched_appeals_on_hold].flatten
  end

  def ama_appeal_stuck?(appeal)
    call.include?(appeal)
  end

  private

  def on_hold
    Constants.TASK_STATUSES.on_hold
  end

  def cancelled
    Constants.TASK_STATUSES.cancelled
  end

  def completed
    Constants.TASK_STATUSES.completed
  end

  def dispatched_appeals_on_hold
    Appeal.where(id: tasks_for(Appeal.name)
      .where(type: RootTask.name, status: on_hold))
      .where(id: completed_dispatch_tasks(Appeal.name))
  end

  def completed_dispatch_tasks(klass_name)
    tasks_for(klass_name).where(type: [BvaDispatchTask.name], status: completed)
  end

  def appeals_with_zero_tasks
    Appeal.established.left_outer_joins(:tasks).where(tasks: { id: nil })
  end

  def tasks_for(klass_name)
    Task.select(:appeal_id).where(appeal_type: klass_name)
  end

  def stuck_appeals
    Appeal.established.active
      .joins(:tasks)
      .group("appeals.id")
      .having("count(tasks) = count(case when tasks.status = 'on_hold' then 1 end)")
  end
end
