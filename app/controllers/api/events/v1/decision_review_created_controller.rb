# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCreatedController < Api::ApplicationController
  def decision_review_created
    # byebug
    consumer_event_id = drc_params[:event_id]
    claim_id = drc_params[:claim_id]
    headers = request.headers
    # check_drc(drc_params)
    ::Events::DecisionReviewCreated.create!(consumer_event_id, claim_id, headers, drc_params)
    render json: { message: "DecisionReviewCreatedEvent successfully processed and backfilled" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    # check if error.message about record already exists in Caseflow
    if error.message.include?("already exists")
      render json: { message: "Record already exists in Caseflow" }, status: :ok
    else
      render json: { message: error.message }, status: :unprocessable_entity
    end
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

  def check_drc
    # note: from consumer comes drc_params with "Unpermitted parameter: :type" message that we can see in rails console. Probably it is a bug.
    category = drc_params[:request_issues].first[:nonrating_issue_category]
    contested_id = drc_params[:request_issues].first[:contested_decision_issue_id]
    ri = RequestIssue.where(contested_decision_issue_id: contested_id)
    if contested_id.present? && ri.length == 1 && category == "Disposition"
      drc_params[:request_issues].first[:nonrating_issue_category] = ri.nonrating_issue_category
    else
      # here is the problem - we can have several "request_issues" here and I need to change
      # code below to go throght all of the and assign  "Unknown Issue Category" to each
      drc_params[:request_issues].first[:nonrating_issue_category] = "Unknown Issue Category"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def drc_params
    params.permit(:event_id,
                  :claim_id,
                  :css_id,
                  :detail_type,
                  :station,
                  intake: {},
                  veteran: {},
                  claimant: {},
                  claim_review: {},
                  end_product_establishment: {},
                  request_issues: [:benefit_type,
                                   :contested_issue_description,
                                   :contention_reference_id,
                                   :contested_rating_decision_reference_id,
                                   :contested_rating_issue_profile_date,
                                   :contested_rating_issue_reference_id,
                                   :contested_decision_issue_id,
                                   :decision_date,
                                   :ineligible_due_to_id,
                                   :ineligible_reason,
                                   :is_unidentified,
                                   :unidentified_issue_text,
                                   :nonrating_issue_category,
                                   :nonrating_issue_description,
                                   :untimely_exemption,
                                   :untimely_exemption_notes,
                                   :vacols_id,
                                   :vacols_sequence_id,
                                   :closed_at,
                                   :closed_status,
                                   :contested_rating_issue_diagnostic_code,
                                   :ramp_claim_id,
                                   :rating_issue_associated_at,
                                   :nonrating_issue_bgs_id,
                                   :nonrating_issue_bgs_source])
  end
  # rubocop:enable Metrics/MethodLength
end
