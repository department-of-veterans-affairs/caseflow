# frozen_string_literal: true

class DocketNumberColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    sort_by_cached_column(tasks, sort_order, "docket_type", "docket_number")
  end
end
