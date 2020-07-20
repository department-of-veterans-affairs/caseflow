# frozen_string_literal: true

class Metrics::DateRange
  include ActiveModel::Validations

  class DateRangeError < StandardError; end

  validate :valid_start_date, :valid_end_date

  class << self
    # returns array of DateRange instances for each month in a fiscal year
    def for_fiscal_year(year)
      months = [10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      # the fiscal year is the year of the last month
      months.map do |month|
        month_start = Date.parse((month > 9) ? "#{year.to_i - 1}-#{month}-1" : "#{year}-#{month}-1")
        new(month_start, month_start.end_of_month)
      end
    end
  end

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def start_date
    @start_date.try(:to_date)
  end

  def end_date
    @end_date.try(:to_date)
  end

  # comparison operator
  def ==(other)
    start_date == other.start_date && end_date == other.end_date
  end

  private

  def valid_start_date
    if start_date.try(:to_date).nil?
      errors.add(:start_date, "Start date must be a valid time string or a Date/Time object")
    end
  end

  def valid_end_date
    if end_date.try(:to_date).nil?
      errors.add(:end_date, "End date must be a valid time string or a Date/Time object")
    end
  end
end
