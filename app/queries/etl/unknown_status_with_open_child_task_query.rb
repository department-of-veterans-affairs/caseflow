# frozen_string_literal: true

class ETL::UnknownStatusWithOpenChildTaskQuery
  def initialize(child_task_type)
    @child_task_type = child_task_type
  end

  def call
    appeals_with_open_child_task
  end

  private

  attr_reader :child_task_type

  def appeals_with_open_child_task
    ETL::Appeal.where(status: "UNKNOWN").where(appeal_id: appeal_ids_for_open_child_tasks_of_type)
  end

  def appeal_ids_for_open_child_tasks_of_type
    ETL::Task.select(:appeal_id)
      .where(appeal_type: "Appeal", task_type: child_task_type, task_status: Task.open_statuses)
  end
end
