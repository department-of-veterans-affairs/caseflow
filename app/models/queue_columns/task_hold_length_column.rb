# frozen_string_literal: true

class TaskHoldLengthColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    tasks.order(placed_on_hold_at: sort_order)
  end
end
