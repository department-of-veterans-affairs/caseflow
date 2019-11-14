# frozen_string_literal: true

class HearingDaysWithVirtualHearingsQuery
  def initialize(hearing_days = HearingDay.all)
    @hearing_days = hearing_days
  end

  # Get IDs for all hearing days that have at least one virtual hearing.
  def call
    @hearing_days
      .where(request_type: HearingDay::REQUEST_TYPES[:video])
      .joins("INNER JOIN hearings ON hearing_days.id = hearings.hearing_day_id")
      .joins("INNER JOIN virtual_hearings ON virtual_hearings.hearing_id = hearings.id")
      .where.not("virtual_hearings.status = ?", :cancelled)
      .distinct
  end
end
