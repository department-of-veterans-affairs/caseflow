# frozen_string_literal: true

class DaysWaitingColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.DAYS_WAITING_COLUMN
    end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[assigned_at]
    end
  end
end
