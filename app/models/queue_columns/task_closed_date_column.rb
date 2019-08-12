# frozen_string_literal: true

class TaskClosedDateColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.TASK_CLOSED_DATE_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    tasks.order(closed_at: sort_order)
  end
end
