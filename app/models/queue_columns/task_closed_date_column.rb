# frozen_string_literal: true

class TaskClosedDateColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.TASK_CLOSED_DATE_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[closed_at]
    end
  end
end
