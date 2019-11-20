# frozen_string_literal: true

# job that sets appeals that are in docket range for the upcoming month

class DocketRangeJob < ApplicationJob
  queue_with_priority :low_priority

  def perform
    DocketCoordinator.new
      .upcoming_appeals_in_range(number_of_days_in_next_month_from_now)
      .update(docket_range_date: one_month_from_now.end_of_month)
  end

  private

  def one_month_from_now
    Time.zone.now + 1.month
  end

  def number_of_days_in_next_month_from_now
    Time.days_in_month(one_month_from_now.month, one_month_from_now.year).days
  end
end
