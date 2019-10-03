# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < Api::V3::BaseController
  SUCCESSFUL_CREATION_HTTP_STATUS = 202

  def create
    if processor.run!.errors?
      render_errors(processor.errors)
      return
    end

    response.set_header(
      "Content-Location",
      url_for(
        controller: :intake_statuses,
        action: :show,
        id: processor.uuid
      )
    )

    render json: intake_status.to_json, status: creation_http_status
  #rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
  #  render_errors([intake_error_code_from_exception_or_processor(error)])
  end

  private

  def processor
    @processor ||= Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(params, User.api_user)
  end

  def intake_status
    @intake_status ||= Api::V3::DecisionReview::IntakeStatus.new(processor.intake)
  end

  # following https://jsonapi.org/recommendations/#asynchronous-processing
  # the first status returned is 202, not 200
  def creation_http_status
    if intake_status.http_status == Api::V3::DecisionReview::IntakeStatus::NOT_SUBMITTED_HTTP_STATUS
      SUCCESSFUL_CREATION_HTTP_STATUS
    else
      intake_status.http_status
    end
  end

  # Try to create an IntakeError from the exception, otherwise the processor's intake object.
  # If neither has an error_code, the IntakeError will be IntakeError::UNKNOWN_ERROR
  def intake_error_code_from_exception_or_processor(exception)
    Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found([exception, processor&.intake])
  end

  def render_errors(errors)
    render Api::V3::DecisionReview::IntakeErrors.new(errors).render_hash
  end
end
