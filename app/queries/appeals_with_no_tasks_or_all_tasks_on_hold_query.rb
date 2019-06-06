# frozen_string_literal: true

class AppealsWithNoTasksOrAllTasksOnHoldQuery
  def call
    [stuck_appeals, stuck_legacy_appeals].flatten
  end

  private

  def stuck_appeals
    stuck_query("Appeal") + zero_tasks_query("Appeal")
  end

  def stuck_legacy_appeals
    stuck_query("LegacyAppeal")
  end

  def zero_tasks_query(klass_name)
    klass_name.constantize.where.not(id: Task.select(:appeal_id).where(appeal_type: klass_name))
  end

  def tasks_for(klass_name)
    Task.select(:appeal_id).where(appeal_type: klass_name)
  end

  def stuck_query(klass_name)
    klass = klass_name.constantize
    table = klass.table_name
    klass.where.not(id: tasks_for(klass_name).inactive)
      .where.not(id: tasks_for(klass_name).where(type: "RootTask", status: Constants.TASK_STATUSES.cancelled))
      .joins(:tasks)
      .group("#{table}.id")
      .having("count(tasks) = count(case when tasks.status = 'on_hold' then 1 end)")
  end
end
