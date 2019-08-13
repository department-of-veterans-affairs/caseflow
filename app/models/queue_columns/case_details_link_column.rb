# frozen_string_literal: true

class CaseDetailsLinkColumn < QueueColumn
  class << self
    def column_name
      Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN
    end

    def sorting_table
      CachedAppeal.table_name
    end

    def sorting_columns
      %w[veteran_name]
    end
  end
end
