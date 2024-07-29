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

    event = DecisionReviewCreatedEvent.find_by(id: consumer_event_id)
    headers = request.headers
    Events::DecisionReviewUpdated.update!(event, headers, drc_params)
    render json: { message: "DecisionReviewCreatedEvent successfully updated" }, status: :ok
  rescue Caseflow::Error::RedisLockFailed => error
    render json: { message: error.message }, status: :conflict
  rescue StandardError => error
    render json: { message: error.message }, status: :unprocessable_entity
  end
  # rubocop:enable Layout/LineLength

  private

  # rubocop:disable Metrics/MethodLength
  def dru_params
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
