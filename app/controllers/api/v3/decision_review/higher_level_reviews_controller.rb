# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < Api::ExternalProxyController
  def create
    processor = Api::V3::HigherLevelReviewProcessor.new(params, current_user)
    if processor.errors?
      render_errors(processor.errors)
      return
    end
    processor.start_review_complete!
    if processor.errors?
      render_errors(processor.errors)
      return
    end
    response.set_header("Content-Location", (
                          request.base_url +
                          "/api/v3/decision_review/higher_level_reviews/intake_status/" +
                          processor.higher_level_review.uuid
                        ))
    render json: self.class.intake_status(processor.higher_level_review), status: :accepted
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render_errors([self.class.error_from_objects_error_code(error, processor.intake)])
  end

  def render_errors(errors)
    render json: { errors: errors }, status: self.class.status_from_errors(errors)
  end

  class << self
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
    def status_from_errors(errors)
      fail ArgumentError, "status_from_errors expects 1 array argument" if errors == {}

      errors.map { |error| Integer error.status }.max || 422
    end

    # given multiple objects, will return the error for the first error code it can find
    def error_from_objects_error_code(*args)
      args.each do |arg|
        code = arg.try(:error_code)
        return Api::V3::HigherLevelReviewProcessor.error_from_error_code(code) if code
      end
      Api::V3::HigherLevelReviewProcessor::ERROR_FOR_UNKNOWN_CODE
    end
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
