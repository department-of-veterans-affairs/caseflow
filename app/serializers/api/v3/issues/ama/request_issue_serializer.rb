# frozen_string_literal: true

# use via `Api::V3::Issues::Ama::RequestIssueSerializer.new(<request issue obj>,
#                 include: [:decision_issues]).serializable_hash.to_json`
# or for a relation example:
#   `Api::V3::Issues::Ama::RequestIssueSerializer.new(
#       RequestIssue.includes(:decision_issues).where(veteran_participant_id: "574727696"), include: [:decision_issues]
#   ).serializable_hash.to_json`
# or with pagination:
#   `Api::V3::Issues::Ama::RequestIssueSerializer.new(
#      RequestIssue.includes(:decision_issues).page(2), include: [:decision_issues]
#   ).serializable_hash.to_json`
class Api::V3::Issues::Ama::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :benefit_type, :closed_at, :closed_status, :contention_reference_id, :contested_decision_issue_id,
             :contested_issue_description, :contested_rating_decision_reference_id,
             :contested_rating_issue_diagnostic_code, :contested_rating_issue_profile_date,
             :contested_rating_issue_reference_id, :corrected_by_request_issue_id,
             :correction_type, :created_at, :decision_date, :decision_review_id,
             :decision_review_type, :edited_description, :end_product_establishment_id,
             :ineligible_due_to_id, :ineligible_reason, :is_unidentified,
             :nonrating_issue_bgs_id, :nonrating_issue_category, :nonrating_issue_description,
             :notes, :ramp_claim_id, :split_issue_status, :unidentified_issue_text,
             :untimely_exemption, :untimely_exemption_notes, :updated_at, :vacols_id,
             :vacols_sequence_id, :verified_unidentified_issue, :veteran_participant_id

  attribute :caseflow_considers_decision_review_active, &:status_active?
  attribute :caseflow_considers_issue_active, &:active?
  attribute :caseflow_considers_title_of_active_review, &:title_of_active_review
  attribute :caseflow_considers_eligible, &:eligible?

  attribute :claimant_participant_id do |object|
    object.decision_review.claimant.participant_id
  end

  attribute :claim_id do |object|
    object&.end_product_establishment&.reference_id
  end

  attribute :decision_issues do |object|
    object.decision_issues.map do |di|
      {
        id: di.id,
        caseflow_decision_date: di.caseflow_decision_date,
        created_at: di.created_at,
        decision_text: di.decision_text,
        deleted_at: di.deleted_at,
        description: di.description,
        diagnostic_code: di.diagnostic_code,
        disposition: di.disposition,
        end_product_last_action_date: di.end_product_last_action_date,
        percent_number: di.percent_number,
        rating_issue_reference_id: di.rating_issue_reference_id,
        rating_profile_date: di.rating_profile_date,
        rating_promulgation_date: di.rating_promulgation_date,
        subject_text: di.subject_text,
        updated_at: di.updated_at
      }
    end
  end
end
