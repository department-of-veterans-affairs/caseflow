# frozen_string_literal: true

class ETL::UnknownStatusWithCompletedRootTaskQuery
  def call
    appeals
  end

  private

  def appeals
    ETL::Appeal.where(status: "UNKNOWN")
      .where(appeal_id: completed_root_tasks)
      .where(appeal_id: open_child_tasks)
  end

  def completed_root_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal", task_type: "RootTask", task_status: Task.closed_statuses)
  end

  def open_child_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal")
      .where.not(task_type: "RootTask", task_status: Task.closed_statuses)
  end
end
