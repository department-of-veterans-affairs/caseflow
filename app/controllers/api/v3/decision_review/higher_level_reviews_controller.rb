# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < Api::ExternalProxyController
  def create
    if processor.run!.errors?
      render_errors(processor.errors)
    else
      response.set_header("Content-Location", url_for(:intake_status, processor.higher_level_review.uuid))
      render Api::V3::DecisionReview::IntakeStatus.new(processor.intake).render_hash
    end
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render_errors(intake_error_from_exception_or_processor(error))
  end

  private

  def processor
    @processor ||= Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(params, current_user)
  end

  # Try to create an IntakeError from the exception, otherwise the processor's intake object.
  # If neither has an error_code, the IntakeError will be IntakeError::UNKNOWN_ERROR
  def intake_error_from_exception_or_processor(exception)
    Api::V3::DecisionReview::IntakeError.new(exception, processor.try(:intake))
  end

  def render_errors(*errors)
    render Api::V3::DecisionReview::IntakeErrors.new(*errors).render_hash
  end
end

# def mock_create
#   mock_hlr = HigherLevelReview.new(
#     uuid: "FAKEuuid-mock-test-fake-mocktestdata",
#     establishment_submitted_at: Time.zone.now # having this timestamp marks it as submitted
#   )
#   response.set_header(
#     "Content-Location",
#     # id returned is static, if a mock intake_status is created, this should match
#     "#{request.base_url}/api/v3/decision_review/higher_level_reviews/intake_status/999"
#   )
#   render json: intake_status(mock_hlr), status: :accepted
# end
