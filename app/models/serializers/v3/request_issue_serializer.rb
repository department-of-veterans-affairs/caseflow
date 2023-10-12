# frozen_string_literal: true

# use via `V3::RequestIssueSerializer.new(<request issue obj>, include: [:decision_issues]).serializable_hash.to_json`
# or for a relation example: `V3::RequestIssueSerializer.new(RequestIssue.where(veteran_participant_id: "574727696"), include: [:decision_issues]).serializable_hash.to_json`
# or with pagination: `V3::RequestIssueSerializer.new(RequestIssue.page(2), include: [:decision_issues]).serializable_hash.to_json`
class V3::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer

  has_many :decision_issues, serializer: V3::DecisionIssueSerializer

  attributes :benefit_type, :closed_status, :contention_reference_id, :contested_decision_issue_id,
             :contested_issue_description, :contested_rating_decision_reference_id,
             :contested_rating_issue_diagnostic_code, :contested_rating_issue_profile_date,
             :contested_rating_issue_reference_id, :corrected_by_request_issue_id,
             :correction_type, :created_at, :decision_date, :decision_review_id,
             :decision_review_type, :edited_description, :end_product_establishment_id,
             :ineligible_due_to_id, :ineligible_reason, :is_unidentified,
             :nonrating_issue_category, :nonrating_issue_description,
             :notes, :ramp_claim_id, :split_issue_status, :unidentified_issue_text,
             :untimely_exemption, :untimely_exemption_notes, :updated_at, :vacols_id,
             :vacols_sequence_id, :verified_unidentified_issue, :veteran_participant_id

end
