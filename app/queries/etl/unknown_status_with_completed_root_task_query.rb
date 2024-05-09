# frozen_string_literal: true

class ETL::UnknownStatusWithCompletedRootTaskQuery
  def call
    unknown_appeals_with_open_child_tasks_and_completed_root_task
  end

  private

  def unknown_appeals_with_open_child_tasks_and_completed_root_task
    ETL::Appeal.where(status: "UNKNOWN")
      .where(appeal_id: appeal_ids_for_completed_root_tasks)
      .where(appeal_id: appeal_ids_for_open_child_tasks)
  end

  def appeal_ids_for_completed_root_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal", task_type: "RootTask", task_status: Task.closed_statuses)
  end

  def appeal_ids_for_open_child_tasks
    ETL::Task.select(:appeal_id).distinct
      .where(appeal_type: "Appeal")
      .where.not(task_type: "RootTask")
      .where.not(task_status: Task.closed_statuses)
  end
end
