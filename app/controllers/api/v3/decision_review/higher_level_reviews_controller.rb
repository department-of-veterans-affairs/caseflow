# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < Api::V3::BaseController
  def create
    if processor.run!.errors?
      render_errors(processor.errors)
    else
      response.set_header(
        "Content-Location",
        url_for(
          controller: :intake_statuses,
          action: :show,
          id: processor.higher_level_review.uuid
        )
      )
      render Api::V3::DecisionReview::IntakeStatus.new(processor.intake).render_hash
    end
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render_errors([intake_error_code_from_exception_or_processor(error)])
  end

  private

  def processor
    @processor ||= begin
                     Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(params, current_user)
                   rescue StandardError
                     nil
                   end
  end

  # Try to create an IntakeError from the exception, otherwise the processor's intake object.
  # If neither has an error_code, the IntakeError will be IntakeError::UNKNOWN_ERROR
  def intake_error_code_from_exception_or_processor(exception)
    Api::V3::DecisionReview::IntakeError.from_first_error_code_found([exception, processor.try(:intake)])
  end

  def render_errors(errors)
    render Api::V3::DecisionReview::IntakeErrors.new(errors).render_hash
  end
end
