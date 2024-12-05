# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController
  # Returns the current active cutoff date that is used to determine if AMA appeals are eligible to
  # have their hearings scheduled as well as if the current_user is authorized to provide new
  # cutoff dates.
  def cutoff_date
    date = SchedulableCutoffDate.most_recently_added&.cutoff_date
    # December 31, 2019 is the fallback date in the event no user-defined cutoff dates exist.
    date ||= Date.new(2019, 12, 31)

    begin
      verified_date = Date.iso8601(date)
    rescue ArgumentError
      return invalid_date
    end

    render json: { cutoff_date: verified_date, user_can_edit: false }
  end

  def update_cutoff_date(cutoff_date)
    record = SchedulableCutoffDate.create!(
      cutoff_date: cutoff_date,
      created_by_id: current_user.id,
      created_at: Time.zone.now
    )
    record
  end

  private

  def invalid_date
    render json: {
      "errors": [
        "status": "400",
        "title": "Invalid Date",
        "detail": "Please enter a valid date"
      ]
    }, status: :unprocessable_entity
  end
end
