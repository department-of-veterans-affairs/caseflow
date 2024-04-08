# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    consumer_event_id = drc_params[:event_id]
    claim_id = drc_params[:claim_id]
    # payload = drc_params[:payload]
    payload = {
      event_id: drc_params[:event_id],
      claim_id: drc_params[:claim_id],
      css_id: drc_params[:css_id],
      detail_type: drc_params[:detail_type],
      station: drc_params[:station],
      intake: drc_params[:intake],
      veteran: drc_params[:veteran],
      claimant: drc_params[:claimant],
      claim_review: drc_params[:claim_review],
      end_product_establishment: drc_params[:end_product_establishment],
      request_issues: drc_params[:request_issues]
    }.as_json
    headers = request.headers
    ::Events::DecisionReviewCreated.create!(consumer_event_id, claim_id, headers, payload)
    render json: { message: "DecisionReviewCreatedEvent successfully processed and backfilled" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  def decision_review_created_error
    event_id = drc_error_params[:event_id]
    errored_claim_id = drc_error_params[:errored_claim_id]
    error_message = drc_error_params[:error]
    ::Events::DecisionReviewCreatedError.handle_service_error(event_id, errored_claim_id, error_message)
    render json: { message: "Decision Review Created Error Saved in Caseflow" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  private

  def drc_error_params
    params.permit(:event_id, :errored_claim_id, :error)
  end

  def drc_params
    # only receiving payload
    params.permit(:event_id, :claim_id, :css_id, :detail_type, :station, :intake, :veteran, :claimant, :claim_review,
     :end_product_establishment, :request_issues)
  end
end
