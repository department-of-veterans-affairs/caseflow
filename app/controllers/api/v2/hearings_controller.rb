# frozen_string_literal: true

class Api::V2::HearingsController < Api::ApplicationController
  def show
    begin
      day = Date.iso8601(params[:hearing_day])
    rescue ArgumentError
      return invalid_date
    end

    begin
      hearings = HearingsForDayQuery.new(day: day).call
    rescue ActiveRecord::RecordNotFound
      return hearing_day_not_found
    end
    hash_serialized = Api::V2::HearingSerializer.new(
      hearings.select { |hearing| hearing.hearing_location.present? && hearing.disposition.nil? }, is_collection: true
    ).serializable_hash[:data]

    render json: {
      hearings: hash_serialized.map { |hearing| hearing[:attributes] }
    }
  end

  private

  def invalid_date
    render json: {
      "errors": [
        "status": "422",
        "title": "Invalid Date",
        "detail": "Please enter a valid date"
      ]
    }, status: :unprocessable_entity
  end

  def hearing_day_not_found
    render json: {
      "errors": [
        "status": "404",
        "title": "Hearing day not found",
        "detail": "No hearing days with that date were found."
      ]
    }, status: :not_found
  end
end
