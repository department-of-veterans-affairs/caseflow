# frozen_string_literal: true

class Api::Events::V1::DecisionReviewCompletedController < Api::ApplicationController
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
    :nonrating_issue_bgs_source,
    :veteran_participant_id
  ].freeze

  def decision_review_completed
    consumer_event_id = drc_params[:event_id]
    claim_id = drc_params[:claim_id]
    headers = request.headers
    consumer_and_claim_ids = { consumer_event_id: consumer_event_id, reference_id: claim_id }
    ::Events::DecisionReviewCompleted.complete!(consumer_and_claim_ids, headers, drc_params)
    render json: { message: "DecisionReviewCopletedEvent successfully processed" }, status: :created
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message + " Record already exists in Caseflow" }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end

  private

  def drc_error_params
    params.permit(:event_id, :errored_claim_id, :error)
  end

  # rubocop:disable Metrics/MethodLength

  def drc_params
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
      completed_issues: REQUEST_ISSUE_ATTRIBUTES
    )
  end

  # rubocop:enable Metrics/MethodLength
end
