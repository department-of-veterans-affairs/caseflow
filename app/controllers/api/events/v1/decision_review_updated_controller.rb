# frozen_string_literal: true

class Api::Events::V1::DecisionReviewUpdatedController < Api::ApplicationController
  # Checks if API is disabled
  before_action do
    if FeatureToggle.enabled?(:disable_ama_eventing)
      render json: {
        errors: [
          {
            status: "501",
            title: "API is disabled",
            detail: "This endpoint is not supported."
          }
        ]
      },
             status: :not_implemented
    end
  end

  REQUEST_ISSUE_ATTRIBUTES = [
    :original_caseflow_request_issue_id,
    :contested_rating_decision_reference_id,
    :contested_rating_issue_reference_id,
    :contested_decision_issue_id,
    :untimely_exemption,
    :untimely_exemption_notes,
    :edited_description,
    :vacols_id,
    :vacols_sequence_id,
    :nonrating_issue_bgs_id,
    :type,
    :decision_review_issue_id,
    :contention_reference_id,
    :benefit_type,
    :contested_issue_description,
    :contested_rating_issue_profile_date,
    :decision_date,
    :ineligible_due_to_id,
    :ineligible_reason,
    :unidentified_issue_text,
    :nonrating_issue_category,
    :nonrating_issue_description,
    :closed_at,
    :closed_status,
    :contested_rating_issue_diagnostic_code,
    :rating_issue_associated_at,
    :ramp_claim_id,
    :is_unidentified,
    :nonrating_issue_bgs_source
  ].freeze

  def decision_review_updated
    consumer_event_id = dru_params[:event_id]
    claim_id = dru_params[:claim_id]
    headers = request.headers
    consumer_and_claim_ids = { consumer_event_id: consumer_event_id, reference_id: claim_id }
    ::Events::DecisionReviewUpdated.update!(consumer_and_claim_ids, headers, dru_params)
    render json: { message: "DecisionReviewUpdatedEvent successfully processed" }, status: :ok
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  def decision_review_updated_error
    event_id = dru_error_params[:event_id]
    errored_claim_id = dru_error_params[:errored_claim_id]
    error_message = dru_error_params[:error]
    ::Events::DecisionReviewUpdatedError.handle_service_error(event_id, errored_claim_id, error_message)
    render json: { message: "Decision Review Updated Error Saved in Caseflow" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  private

  # rubocop:disable Metrics/MethodLength

  def dru_error_params
    params.permit(:event_id, :errored_claim_id, :error)
  end

  def dru_params
    params.permit(
      :event_id,
      :claim_id,
      :css_id,
      :detail_type,
      :station,
      claim_review: [
        :auto_remand,
        :remand_source_id,
        :informal_conference,
        :same_office,
        :legacy_opt_in_approved
      ],
      end_product_establishment: [
        :code,
        :development_item_reference_id,
        :reference_id,
        :synced_status,
        :last_synced_at
      ],
      added_issues: REQUEST_ISSUE_ATTRIBUTES,
      updated_issues: REQUEST_ISSUE_ATTRIBUTES,
      removed_issues: REQUEST_ISSUE_ATTRIBUTES,
      withdrawn_issues: REQUEST_ISSUE_ATTRIBUTES,
      ineligible_to_eligible_issues: REQUEST_ISSUE_ATTRIBUTES,
      eligible_to_ineligible_issues: REQUEST_ISSUE_ATTRIBUTES,
      ineligible_to_ineligible_issues: REQUEST_ISSUE_ATTRIBUTES
    )
  end
  # rubocop:enable Metrics/MethodLength
end
