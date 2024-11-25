# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController

  # Returns the current active cutoff date that is used to determine if AMA appeals are eligible to
  # have their hearings scheduled as well as if the current_user is authorized to provide new
  # cutoff dates.
  def cutoff_date
    render json: {
      # December 31, 2019 is the fallback date in the event no user-defined cutoff dates exist.
      cutoff_date: SchedulableCutoffDate.most_recently_added&.cutoff_date || Date.new(2019, 12, 31),
      user_can_edit: false
    }
  end
end
