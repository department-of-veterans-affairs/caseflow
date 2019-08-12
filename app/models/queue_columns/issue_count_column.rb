# frozen_string_literal: true

class IssueCountColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    sort_by_cached_column(tasks, sort_order, "issue_count")
  end
end
