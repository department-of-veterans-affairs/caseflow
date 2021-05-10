# frozen_string_literal: true

class Hearings::HearingDay::FilledHearingSlotsController < ApplicationController
  include HearingsConcerns::VerifyAccess
  include HearingConcern

  before_action :verify_edit_hearing_schedule_access

  def index
    hearing_day = ::HearingDay.find_by(id: params[:hearing_day_id])

    render json: { filled_hearing_slots: filled_hearing_slots(hearing_day) }
  end

  private

  def filled_hearing_slots(hearing_day)
    return if hearing_day.nil?

    open_hearings = hearing_day.open_hearings

    open_hearings.map do |hearing|
      {
        external_id: hearing.external_id,
        hearing_time: hearing.scheduled_time_string,
        issue_count: hearing.current_issue_count,
        docket_number: hearing.docket_number,
        docket_name: hearing.docket_name,
        poa_name: poa_name(hearing)
      }
    end
  end
end
