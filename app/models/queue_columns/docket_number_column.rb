# frozen_string_literal: true

class DocketNumberColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
    end

    def sorting_table
      CachedAppeal.table_name
    end

    def sorting_columns
      %w[docket_type docket_number]
    end
  end
end
