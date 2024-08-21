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

  # rubocop:disable Layout/LineLength
  def decision_review_updated
    consumer_event_id = dru_params[:event_id]
    return render json: { message: "Record not found in Caseflow" }, status: :not_found unless Event.exists_and_is_completed?(consumer_event_id)

    claim_id = dru_params[:claim_id]
    headers = request.headers
    consumer_and_claim_ids = { consumer_event_id: consumer_event_id, reference_id: claim_id }
    Events::DecisionReviewUpdated.update!(consumer_and_claim_ids, headers, dru_params)
    render json: { message: "DecisionReviewCreatedEvent successfully updated" }, status: :ok
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
  # rubocop:enable Layout/LineLength

  private

  # rubocop:disable Metrics/MethodLength

  def dru_error_params
    params.permit(:event_id, :errored_claim_id, :error)
  end

  def dru_params
    params.permit(
      :event_id,
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
      end_product_establishments: [
        :development_item_reference_id,
        :reference_id
      ],
      request_issues: [
        :id,
        :benefit_type,
        :closed_at,
        :closed_status,
        :contention_reference_id,
        :contested_issue_description,
        :contested_rating_issue_diagnostic_code,
        :contested_rating_issue_reference_id,
        :contested_rating_issue_profile_date,
        :contested_decision_issue_id,
        :decision_date,
        :ineligible_due_to_id,
        :ineligible_reason,
        :is_unidentified,
        :unidentified_issue_text,
        :nonrating_issue_category,
        :nonrating_issue_description,
        :nonrating_issue_bgs_id,
        :nonrating_issue_bgs_source,
        :ramp_claim_id,
        :rating_issue_associated_at,
        :untimely_exemption,
        :untimely_exemption_notes,
        :vacols_id,
        :vacols_sequence_id,
        :veteran_participant_id
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength
end
