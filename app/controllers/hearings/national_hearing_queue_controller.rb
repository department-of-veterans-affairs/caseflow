# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController

  def index
    respond_to do |format|
      format.html { render "national_hearing_queue/index" }
      format.json { queue_entries }
    end
  end

  # Returns the current active cutoff date that is used to determine if AMA appeals are eligible to
  # have their hearings scheduled as well as if the current_user is authorized to provide new
  # cutoff dates.
  def cutoff_date
    date = SchedulableCutoffDate.most_recently_added&.cutoff_date
    # December 31, 2019 is the fallback date in the event no user-defined cutoff dates exist.
    date ||= Date.new(2019, 12, 31)

    render json: { cutoff_date: date, user_can_edit: false }
  end
end
