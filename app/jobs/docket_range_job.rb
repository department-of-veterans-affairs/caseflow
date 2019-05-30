# frozen_string_literal: true

# job that sets appeals that are in docket range for the upcoming month

class DocketRangeJob < ApplicationJob
  queue_as :low_priority

  def perform
    for_month = Time.zone.now + 1.month
    days_in_month = Time.days_in_month(for_month.month, for_month.year)
    dc = DocketCoordinator.new
    target = dc.target_number_of_ama_hearings(days_in_month.days)
    appeals_to_mark = dc.dockets[:hearing].appeals(priority: false).where(docket_range_date: false).limit(target)

    appeals_to_mark.update(docket_range_date: Time.utc(for_month.year, for_month.month, 1))
  end
end
