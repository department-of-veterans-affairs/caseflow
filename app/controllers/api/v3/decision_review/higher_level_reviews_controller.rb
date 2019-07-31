# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    processor = Api::V3::HigherLevelReviewProcessor.new(params)

    if processor.errors?
      status = processor.errors.map { |error| error[:status] }.max
      render json: { errors: processor.errors }, status: status
      return
    end

    processor.build_start_review_complete

    higher_level_review = processor.higher_level_review
    uuid = higher_level_review.uuid

    response.set_header(
      "Content-Location",
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/#{uuid}"
    )

    render json: intake_status(higher_level_review), status: :accepted
  rescue StandardError => error
    status, title = (
      case (processor.intake.try(:error_code) || error.try(:error_code)).to_s
      when "invalid_file_number"
        [422, "Veteran ID not found"]
      when "veteran_not_found"
        [404, "Veteran not found"]
      when "veteran_has_multiple_phone_numbers"
        [422, "The Veteran has multiple active phone numbers"]
      when "veteran_not_accessible"
        [403, "You don't have permission to view this Veteran's information"]
      when "veteran_not_modifiable"
        [422, "You don't have permission to intake this Veteran"]
      when "veteran_not_valid"
        [422, "The Veteran's profile has missing or invalid information required to create an EP."]
      when "duplicate_intake_in_progress"
        [409, "Intake In Progress"]
      when "reserved_veteran_file_number"
        [422, "Invalid veteran file number"]
      when "incident_flash"
        [422, "The veteran has an incident flash"]
      else; [nil, nil]
      end
    )
    unless status || title
      status = 422
      title = "Unknown error"
      code = "unknown_error"
    end

    render json: { errors: [{ status: status, title: title, code: code }] }, status: status
  end

  def mock_create
    mock_hlr = HigherLevelReview.new(
      uuid: "FAKEuuid-mock-test-fake-mocktestdata",
      establishment_submitted_at: Time.zone.now # having this timestamp marks it as submitted
    )
    response.set_header(
      "Content-Location",
      # id returned is static, if a mock intake_status is created, this should match
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/999"
    )
    render json: intake_status(mock_hlr), status: :accepted
  end

  private

  def intake_status(higher_level_review)
    {
      data: {
        type: "IntakeStatus",
        id: higher_level_review.uuid,
        attributes: {
          status: higher_level_review.asyncable_status
        }
      }
    }
  end
end
