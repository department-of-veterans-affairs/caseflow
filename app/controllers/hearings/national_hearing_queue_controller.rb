# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController
  # skip_before_action :verify_authenticity_token

  def index
    respond_to do |format|
      format.html { render "national_hearing_queue/index" }
    end
  end

  # Returns the current active cutoff date that is used to determine if AMA appeals are eligible to
  # have their hearings scheduled as well as if the current_user is authorized to provide new
  # cutoff dates.
  def cutoff_date
    byebug

    date = SchedulableCutoffDate.most_recently_added&.cutoff_date
    # December 31, 2019 is the fallback date in the event no user-defined cutoff dates exist.
    date ||= Date.new(2019, 12, 31)

    render json: { cutoff_date: date, user_can_edit: false }
  end

  def update_cutoff_date
    required_params = params.require(:cutoff_date)

    begin
      Date.iso8601(required_params[:cutoff_date])

      record = SchedulableCutoffDate.create!(
        cutoff_date: required_params[:cutoff_date],
        created_by_id: current_user.id,
        created_at: Time.zone.now
      )
    rescue Date::Error => error
      log_error(error)
      return invalid_date
    rescue StandardError => error
      log_error(error)
      return does_not_persist
    end

    render json: { cutoff_date_record: record }, status: :created
  end

  private

  def invalid_date
    render json: {
      "errors": [
        "status": "400",
        "title": "Invalid Date",
        "detail": "Please enter a valid date",
        "error_code": error_uuid
      ]
    }, status: :bad_request
  end

  def does_not_persist
    render json: {
      "errors": [
        "status": "500",
        "title": "Internal Service Error",
        "detail": "Cutoff date unable to persist, try again at a later time",
        "error_code": error_uuid
      ]
    }, status: :internal_server_error
  end

  def log_error(error)
    Rails.logger.error(error)
    Rails.logger.error(error.backtrace.join("\n"))
    Rails.logger.error(error_uuid)
  end
end
