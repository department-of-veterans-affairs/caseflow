# frozen_string_literal: true

class RegionalOfficesController < ApplicationController
  def index
    render json: {
      regional_offices: RegionalOffice.ros_with_hearings.merge("C" => RegionalOffice::CITIES["C"])
    }
  end

  def open_hearing_dates
    ro = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days = HearingDay.open_hearing_days_with_hearings_hash(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      ro
    )

    render json: {
      hearing_days: hearing_days.map do |day|
        {
          hearing_id: day["id"],
          regional_office: ro,
          timezone: RegionalOffice::CITIES[ro][:timezone],
          scheduled_for: day["scheduled_for"],
          request_type: day["request_type"],
          room: day["room"],
          total_slots: day["total_slots"]
        }
      end
    }
  end
end
