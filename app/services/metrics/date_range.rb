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
    @start_date.try(:to_date)
  end

  def end_date
    @end_date.try(:to_date)
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
