# frozen_string_literal: true

# job that sets appeals that are in docket range for the upcoming month

class DocketRangeJob < ApplicationJob
  queue_as :low_priority

  def perform
    for_month = Time.zone.now + 1.month
    days_in_month = Time.days_in_month(for_month.month, for_month.year)
    end_of_month = Time.utc(for_month.year, for_month.month, for_month.end_of_month.day)
    appeals_to_mark(days_in_month).update(docket_range_date: end_of_month)
  end

  def appeals_to_mark(days_in_month)
    dc = DocketCoordinator.new
    target = dc.target_number_of_ama_hearings(days_in_month.days)
    dc.dockets[:hearing].appeals(priority: false).where(docket_range_date: nil).limit(target)
  end
end
