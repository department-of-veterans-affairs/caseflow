# frozen_string_literal: true

class ETL::UnknownStatusWithClosedTasksQuery
  def call
    unknown_appeals_with_all_closed_child_tasks
  end

  private

  def unknown_appeals_with_all_closed_child_tasks
    ETL::Appeal.where(status: "UNKNOWN").where.not(appeal_id: appeal_ids_for_open_tasks)
  end

  def appeal_ids_for_open_tasks
    ETL::Task.select(:appeal_id).where(appeal_type: "Appeal", task_status: Task.open_statuses).distinct
  end
end
