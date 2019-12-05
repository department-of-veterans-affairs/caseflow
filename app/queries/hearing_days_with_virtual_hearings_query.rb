# frozen_string_literal: true

class HearingDaysWithVirtualHearingsQuery
  def initialize(hearing_days = HearingDay.all)
    @hearing_days = hearing_days
  end

  def for_ama_hearings
    @hearing_days
      .where(request_type: HearingDay::REQUEST_TYPES[:video])
      .joins("INNER JOIN hearings ON hearing_days.id = hearings.hearing_day_id")
      .joins("INNER JOIN virtual_hearings ON virtual_hearings.hearing_id = hearings.id")
      .where.not("virtual_hearings.status = ?", :cancelled)
      .distinct
  end

  def for_legacy_hearings
    @hearing_days
      .where(request_type: HearingDay::REQUEST_TYPES[:video])
      .joins("INNER JOIN legacy_hearings ON hearing_days.id = legacy_hearings.hearing_day_id")
      .joins("INNER JOIN virtual_hearings ON virtual_hearings.hearing_id = legacy_hearings.id")
      .where.not("virtual_hearings.status = ?", :cancelled)
      .distinct
  end

  # Get IDs for all hearing days that have at least one virtual hearing.
  def call
    for_ama_hearings + for_legacy_hearings
  end
end
