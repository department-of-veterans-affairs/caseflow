# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatusesController < Api::V3::BaseController
  def show
    unless decision_review
      render_no_decision_review_error
      return
    end

    response.set_header("Location", decision_review_url) if intake_status.submitted?
    render json: intake_status.to_json, status: intake_status.http_status
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
      title: "Unable to find a DecisionReview with uuid: #{uuid}"
    )
  end

  def render_error(status:, code:, title:)
    render(
      json: { errors: [{ status: status, code: code, title: title }] },
      status: status
    )
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
