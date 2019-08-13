# frozen_string_literal: true

class RegionalOfficeColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
    end

    def sorting_table
      CachedAppeal.table_name
    end

    def sorting_columns
      %w[closest_regional_office_city]
    end
  end
end
