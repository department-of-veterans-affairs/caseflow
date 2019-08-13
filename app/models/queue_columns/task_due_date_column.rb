# frozen_string_literal: true

class TaskDueDateColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.TASK_DUE_DATE_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[assigned_at]
    end
  end
end
