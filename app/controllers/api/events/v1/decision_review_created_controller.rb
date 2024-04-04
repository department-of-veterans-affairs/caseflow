# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    consumer_event_id = drc_params[:event_id]
    claim_id = drc_params[:claim_id]
    payload = drc_params[:payload]
    headers = request.headers
    ::Events::DecisionReviewCreated.create!(consumer_event_id, claim_id, headers, payload)
    render json: { message: "DecisionReviewCreatedEvent successfully processed and backfilled" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    binding.pry
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
    params.permit(:event_id, :claim_id, :payload)
  end
end
