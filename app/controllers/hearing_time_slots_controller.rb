# frozen_string_literal: true

class HearingTimeSlotsController < ApplicationController
  def index
    hearing_day = HearingDay.find_by(id: params[:hearing_day_id])

    render json: { hearing_time_slots: hearing_times(hearing_day)}
  end

  private

  def hearing_key(hearing)
    hearing.class.name + hearing.id.to_s
  end

  def hearing_attributes(scheduled_times, hearings, hearing_type)
    hearings = hearing_type.where(id: hearings.select { |h| h.is_a?(hearing_type) }.map(&:id))
    hearings.with_cached_appeals.select("cached_appeal_attributes.*").map do |hearing|
      {
        hearing_time: scheduled_times[hearing_key(hearing)]
        issue_count: hearing[:issue_count],
        docket_number: hearing[:docket_number],
        docket_name: hearing[:docket_name],
        poa_name: hearing[:power_of_attorney_name]
      }
    end
  end

  def hearing_times(hearing_day)
    open_hearings = hearing_day.open_hearings
    scheduled_times = open_hearing.map do |hearing|
      [hearing_key(hearing), hearing.scheduled_time_string]
    end.to_h

    hearing_attributes(scheduled_times, open_hearings, Hearing) +
      hearing_attributes(scheduled_times, open_hearings, LegacyHearing)
  end
end
