# frozen_string_literal: true

class TaskCreatedAtColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.TASK_CREATED_AT_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[created_at]
    end
  end
end
