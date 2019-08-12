# frozen_string_literal: true

class TaskTypeColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    tasks.order(type: sort_order, action: sort_order, created_at: sort_order)
  end
end
