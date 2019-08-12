# frozen_string_literal: true

class CaseDetailsLinkColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    sort_by_cached_column(tasks, sort_order, "veteran_name")
  end
end
