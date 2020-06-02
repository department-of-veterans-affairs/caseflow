# frozen_string_literal: true

class ETL::UnknownStatusWithOpenRootTaskQuery
  def call
    appeals
  end

  private

  def appeals
    ETL::Appeal.where(status: "UNKNOWN").where(appeal_id: open_root_tasks).where(appeal_id: open_child_tasks)
  end

  def open_root_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal", task_type: "RootTask")
      .where(task_status: Task.open_statuses)
  end

  def open_child_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal")
      .where.not(task_type: "RootTask", task_status: Task.closed_statuses)
  end
end
