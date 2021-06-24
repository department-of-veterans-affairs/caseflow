# frozen_string_literal: true

class RegionalOfficesController < ApplicationController
  def index
    ros = RegionalOffice.ros_with_hearings.merge("C" => RegionalOffice::CITIES["C"])

    if !FeatureToggle.enabled?(:national_vh_queue, user: current_user)
      ros.delete_if { |ro_key, _ro| ro_key == "R" }
    end

    render json: { regional_offices: ros }
  end

  def hearing_dates
    ro = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days = HearingDayRange.new(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      ro
    ).all_hearing_days

    render json: {
      hearing_days: hearing_days.map { |day, hearings| RegionalOfficesController.hearing_day_hash(ro, day, hearings) }
    }
  end

  class << self
    def hearing_day_hash(regional_office, day, hearings)
      {
        hearing_id: day.id,
        vlj: day.judge ? "VLJ #{day.judge&.full_name&.split(' ')&.last}" : nil,
        regional_office: regional_office,
        timezone: RegionalOffice::CITIES[regional_office][:timezone],
        scheduled_for: day.scheduled_for,
        readable_request_type: Hearing::HEARING_TYPES[day.request_type.to_sym],
        room: day.room,
        room_label: HearingRooms.find!(day.room)&.label || "",
        filled_slots: hearings.size,
        total_slots: day.total_slots,
        begins_at: day.begins_at,
        slot_length_minutes: day.slot_length_minutes
      }
    end
  end
end
