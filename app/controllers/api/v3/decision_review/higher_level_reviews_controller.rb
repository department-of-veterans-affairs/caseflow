# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    preintake = Api::V3::HigherLevelReviewPreintake.new(params)

    if preintake.errors
      status = preintake.errors.map{|error| error[:status]}.max
      render json: {errors: preintake.errors}, status: status
      return
    end
    
    preintake.complete_review!
    
    higher_level_review = preintake.higher_level_review
    uuid = higher_level_review.uuid
    
    response.set_header(
      "Content-Location",
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/#{uuid}"
    )

    render json: intake_status(higher_level_review), status: :accepted
  rescue StandardError
    render json: {errors: [{status: 422, code: unknown_error, title: "Unknown error"}]}, status: 422
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
