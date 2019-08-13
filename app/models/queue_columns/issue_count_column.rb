# frozen_string_literal: true

class IssueCountColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN
    end

    def sorting_table
      CachedAppeal.table_name
    end

    def sorting_columns
      %w[issue_count]
    end
  end
end
