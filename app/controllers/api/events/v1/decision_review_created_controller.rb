# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    render json: { message: "Decision Review Created" }, status: :created
  end

  def decision_review_created_error
    event_id = dcr_error_params[:event_id]
    errored_claim_id = dcr_error_params[:errored_claim_id]
    error = dcr_error_params[:error]
    ::Events::DecisionReviewCreatedError.handle_service_error(event_id, errored_claim_id, error)
    render json: { message: "Decision Review Created Error Saved in Caseflow" }, status: :created
  end

  private

  def dcr_error_params
    params.permit(:event_id, :errored_claim_id, :error)
  end
end
