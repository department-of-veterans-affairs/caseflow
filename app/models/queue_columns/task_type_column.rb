# frozen_string_literal: true

class TaskTypeColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[type action created_at]
    end
  end
end
