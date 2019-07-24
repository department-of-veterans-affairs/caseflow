# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    begin
      @request = HigherLevelReviewRequest.new params
    rescue StandardError
      render error status: 400, title: "Malformed request"
    end

    transaction do
      render error unless intake.start! # make these errors more specific
      render error unless intake.review! @request.review_hash
      render error unless intake.complete! @request.complete_hash
    end

    higher_level_review = intake.detail

    uuid = higher_level_review.uuid
    response.set_header(
      "Content-Location",
      "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/#{uuid}"
    )
    render json: intake_status(higher_level_review), status: :accepted
  rescue StandardError
    render error
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

  def error(*args)
    ErrorRenderHash.new(*args).render_hash
  end

  def intake
    @intake ||= Intake.build(
      user: current_user,
      veteran_file_number: @request.veteran.file_number,
      form_type: "higher_level_review"
    )
  end
end
