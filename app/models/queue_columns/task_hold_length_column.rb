# frozen_string_literal: true

class TaskHoldLengthColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[placed_on_hold_at]
    end
  end
end
