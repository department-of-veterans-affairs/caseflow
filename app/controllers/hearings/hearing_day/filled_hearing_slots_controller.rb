# frozen_string_literal: true

class Hearings::HearingDay::FilledHearingSlotsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_edit_hearing_schedule_access

  def index
    hearing_day = ::HearingDay.find_by(id: params[:hearing_day_id])

    render json: { filled_hearing_slots: filled_hearing_slots(hearing_day) }
  end

  private

  def poa_name(hearing)
    poa = if hearing.is_a?(Hearing)
            BgsPowerOfAttorney.find_by(claimant_participant_id: hearing.appeal.claimant.participant_id)
          elsif hearing.is_a?(LegacyHearing)
            BgsPowerOfAttorney.find_by(file_number: hearing.appeal.veteran_file_number)
          end

    poa&.representative_name
  end

  def filled_hearing_slots(hearing_day)
    return if hearing_day.nil?

    open_hearings = hearing_day.open_hearings

    open_hearings.map do |hearing|
      {
        hearing_time: hearing.scheduled_time_string,
        issue_count: hearing.current_issue_count,
        docket_number: hearing.docket_number,
        docket_name: hearing.docket_name,
        poa_name: poa_name(hearing)
      }
    end
  end
end
