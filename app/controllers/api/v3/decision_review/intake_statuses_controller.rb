# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatusesController < Api::V3::BaseController
  def show
    if !decision_review
      render_no_decision_review_error
      return
    end

    render_intake_status_for_decision_review
  rescue StandardError
    render_unknown_error
  end

  private

  def uuid
    params[:id]
  end

  def decision_review
    @decision_review ||= DecisionReview.by_uuid(uuid)
  end

  def intake
    @intake ||= decision_review.intake
  end

  def intake_status
    @intake_status ||= Api::V3::DecisionReview::IntakeStatus.new(intake)
  end

  def render_unknown_error
    render_error status: 500, code: :unknown_error, title: "Unknown error"
  end

  def render_no_decision_review_error
    render_error(
      status: 404,
      code: :decision_review_not_found,
      title: "Unable to find a Decision Review using specified UUID"
    )
  end

  def render_intake_status_for_decision_review
    intake_status.processed? ? render_processed_intake_status : render_unprocessed_intake_status
  end

  def render_processed_intake_status
    response.set_header("Location", decision_review_url)
    render json: { meta: { Location: decision_review_url } }, status: intake_status.http_status
  end

  def render_unprocessed_intake_status
    render json: intake_status.to_json, status: intake_status.http_status
  end

  def decision_review_url
    url_for(
      controller: decision_review_controller,
      action: :show,
      id: decision_review.uuid
    )
  end

  def decision_review_controller
    decision_review.class.name.underscore.pluralize.to_sym
  end
end
