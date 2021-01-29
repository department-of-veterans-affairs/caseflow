# frozen_string_literal: true

class Api::V3::DecisionReviews::HigherLevelReviewsController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  before_action do
    api_released?(:api_v3_higher_level_reviews)
  end

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

    render json: intake_status.to_json, status: intake_status.http_status_for_new_intake
  rescue StandardError => error
    # do we want something like intakes_controller's log_error here?
    render_errors([intake_error_code_from_exception_or_processor(error)])
  end

  def show
    higher_level_review = HigherLevelReview.find_by_uuid(params[:id])
    options = { include: [:veteran, :claimant, :request_issues, :decision_issues] }
    render json: Api::V3::HigherLevelReviewSerializer.new(higher_level_review, options)
  end

  private

  def processor
    @processor ||= Api::V3::DecisionReviews::HigherLevelReviewIntakeProcessor.new(
      params.except(:controller, :action),
      User.api_user
    )
  end

  def intake_status
    @intake_status ||= Api::V3::DecisionReviews::IntakeStatus.new(processor.intake)
  end

  # Try to create an IntakeError from the exception, otherwise the processor's intake object.
  # If neither has an error_code, the IntakeError will be IntakeError::UNKNOWN_ERROR
  def intake_error_code_from_exception_or_processor(exception)
    Api::V3::DecisionReviews::IntakeError.new_from_first_error_code([exception, processor&.intake])
  end

  def render_errors(errors)
    render Api::V3::DecisionReviews::IntakeErrors.new(errors).render_hash
  end
end
