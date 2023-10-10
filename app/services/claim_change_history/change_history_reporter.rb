# frozen_string_literal: true

class ChangeHistoryReporter
  attr_reader :business_line

  CHANGE_HISTORY_COLUMNS = %w[].freeze

  def initialize(events = [], filters = {})
    @events = events
    @filters = filters
  end

  # :reek:FeatureEnvy
  def as_csv
    CSV.generate do |csv|
      csv << format_filters_row
      csv << CHANGE_HISTORY_COLUMNS
      @events.each do |event|
        csv << event.to_csv_row
      end
    end
  end

  private

  def format_filters_row
    @filters.to_a
  end
end
