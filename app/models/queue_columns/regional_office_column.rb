# frozen_string_literal: true

class RegionalOfficeColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
  end

  private

  def unsafe_sort_tasks(tasks, sort_order)
    sort_by_cached_column(tasks, sort_order, "closest_regional_office_city")
  end
end
