# frozen_string_literal: true

class DaysWaitingColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    tasks.order(assigned_at: sort_order)
  end
end
