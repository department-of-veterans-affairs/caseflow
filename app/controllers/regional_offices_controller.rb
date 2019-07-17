# frozen_string_literal: true

class RegionalOfficesController < ApplicationController
  def index
    render json: {
      regional_offices: RegionalOffice.ros_with_hearings.merge("C" => RegionalOffice::CITIES["C"])
    }
  end

  def hearing_dates
    ro = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days = HearingDay.all_hearing_days_with_hearings_hash(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      ro
    )

    render json: {
      hearing_days: hearing_days.map { |day| RegionalOfficesController.hearing_day_hash(ro, day) }
    }
  end

  class << self
    def hearing_day_hash(regional_office, day)
      {
        hearing_id: day["id"],
        regional_office: regional_office,
        timezone: RegionalOffice::CITIES[regional_office][:timezone],
        scheduled_for: day["scheduled_for"],
        request_type: day["request_type"],
        room: day["room"],
        filled_slots: day["hearings"].size,
        total_slots: day["total_slots"]
      }
    end
  end
end
