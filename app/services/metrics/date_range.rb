# frozen_string_literal: true

class Metrics::DateRange
  include ActiveModel::Validations

  class DateRangeError < StandardError; end

  validate :valid_start_date, :valid_end_date

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def start_date
    @start_date.to_date
  end

  def end_date
    @end_date.to_date
  end

  private

  def valid_start_date
    unless start_date.respond_to?(:to_date)
      errors.add(:start_date, "Start date must be a valid time string or a Date/Time object")
    end
  end

  def valid_end_date
    unless end_date.respond_to?(:to_date)
      errors.add(:end_date, "End date must be a valid time string or a Date/Time object")
    end
  end
end
