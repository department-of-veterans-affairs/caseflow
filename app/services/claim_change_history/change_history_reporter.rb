# frozen_string_literal: true

class ChangeHistoryReporter
  attr_reader :business_line

  CHANGE_HISTORY_COLUMNS = %w[].freeze

  def initialize(business_line, filters = {})
    @business_line = business_line
    @filters = filters
  end

  def as_csv
    CSV.generate do |csv|
      csv << format_filters_row
      csv << CHANGE_HISTORY_COLUMNS
    end
  end

  private

  def format_filters_row
    @filters.to_a
  end
end
