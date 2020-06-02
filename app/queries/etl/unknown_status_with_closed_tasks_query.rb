# frozen_string_literal: true

class ETL::UnknownStatusWithClosedTasksQuery
  def call
    appeals
  end

  private

  def appeals
    ETL::Appeal.where(status: "UNKNOWN").where.not(appeal_id: open_tasks)
  end

  def open_tasks
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal")
      .where(task_status: Task.open_statuses)
  end
end
