# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    processor = Api::V3::HigherLevelReviewProcessor.new(params, current_user)
    render_errors(processor.errors) && return if processor.errors?

    processor.start_review_complete!
    render_errors(processor.errors) && return if processor.errors?

    higher_level_review = processor.higher_level_review
    uuid = higher_level_review.uuid

    response.set_header(
      "Content-Location",
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/#{uuid}"
    )

    render json: intake_status(higher_level_review), status: :accepted
  rescue StandardError => error
    # TODO: log_error
    # TODO error_uuid

    # defaults to ERROR_FOR_UNKNOWN_CODE
    error = processor.error_from_error_code(error.try(:error_code) || processor.intake.try(:error_code))
    render_errors([error])
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

  # errors should be an array of Api::V3::HigherLevelReviewProcessor::Error
  def render_errors(errors)
    render json: { errors: errors }, status: errors.map(&:status).max
  end
end
