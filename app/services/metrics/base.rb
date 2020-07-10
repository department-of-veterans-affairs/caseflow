# frozen_string_literal: true

class Metrics::Base
  attr_reader :date_range

  delegate :start_date, :end_date, to: :date_range

  def initialize(date_range)
    fail Metrics::DateRange::DateRangeError if date_range.invalid?

    @date_range = date_range
  end

  def call; end

  def id; end

  def name; end
end
