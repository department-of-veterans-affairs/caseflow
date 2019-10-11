# frozen_string_literal: true
require_dependency Rails.root.join('app', 'serializers', 'api', 'v3', 'higher_level_review')

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
          id: processor.uuid
        )
      )
      render Api::V3::DecisionReview::IntakeStatus.new(processor.intake).render_hash
    end
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render_errors([intake_error_code_from_exception_or_processor(error)])
  end

  def show
    higher_level_review = HigherLevelReview.find_by_uuid(params[:id])
    render json: Api::V3::HigherLevelReviewSerializer.new(higher_level_review)
  end

  private

  def processor
    @processor ||= Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(params, User.api_user)
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
