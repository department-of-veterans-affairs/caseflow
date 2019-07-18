# frozen_string_literal: true

class AppealsWithNoTasksOrAllTasksOnHoldQuery
  def call
    [stuck_appeals, appeals_with_zero_tasks].flatten
  end

  private

  def stuck_appeals
    stuck_query("Appeal")
  end

  def appeals_with_zero_tasks
    Appeal.where.not(id: Task.select(:appeal_id).where(appeal_type: Appeal.name))
  end

  def tasks_for(klass_name)
    Task.select(:appeal_id).where(appeal_type: klass_name)
  end

  def stuck_query(klass_name)
    klass = klass_name.constantize
    table = klass.table_name
    klass.where.not(id: tasks_for(klass_name).closed)
      .where.not(id: tasks_for(klass_name).where(type: "RootTask", status: Constants.TASK_STATUSES.cancelled))
      .joins(:tasks)
      .group("#{table}.id")
      .having("count(tasks) = count(case when tasks.status = 'on_hold' then 1 end)")
  end
end
