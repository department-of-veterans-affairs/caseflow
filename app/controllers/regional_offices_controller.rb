class RegionalOfficesController < ApplicationController
  def index
    render json: {
      regional_offices: RegionalOffice.ros_with_hearings
    }
  end

  def open_hearing_dates
    ro = params[:regional_office]
    hearing_dates = HearingDay.load_days_with_open_hearing_slots(Date.today, Date.today + 365, ro)
    render json: {
      hearing_dates: hearing_dates.map do |date|
        {
          id: date[:id],
          hearing_date: date[:hearing_date],
          hearing_type: date[:hearing_type],
          room_info: date[:room_info],
          total_slots: date[:total_slots]
        }
      end
    }
  end
end
