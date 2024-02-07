# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    consumer_event_id = drc_params[:event_id]
    claim_id = drc_params[:claim_id]
    ::Events::DecisionReviewCreated.create(consumer_event_id, claim_id)
    render json: { message: "DecisionReviewCreatedEvent successfully processed and backfilled" }, status: :created
  rescue CaseFlow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  def decision_review_created_error
    render json: { message: "Error Creating Decision Review" }, status: :method_not_allowed
  end

  private

  def drc_params
    params.permit(:event_id, :claim_id)
  end
end
