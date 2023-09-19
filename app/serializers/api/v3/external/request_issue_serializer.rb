# frozen_string_literal: true

class Api::V3::External::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :benefit_type
  attribute :closed_status
  attribute :closed_status
  attribute :contention_reference_id
  attribute :contested_decision_issue_id
  attribute :contested_issue_description
  attribute :contested_rating_decision_reference_id
  attribute :contested_rating_issue_diagnostic_code
  attribute :contested_rating_issue_profile_date
  attribute :contested_rating_issue_reference_id
  attribute :corrected_by_request_issue_id
  attribute :correction_type
  attribute :created_at
  attribute :decision_date
  attribute :decision_review_id
  attribute :decision_review_type
  attribute :edited_description
  attribute :end_product_establishment_id
  attribute :ineligible_due_to_id
  attribute :ineligible_reason
  attribute :is_unidentified
  attribute :nonrating_issue_category
  attribute :nonrating_issue_description
  attribute :notes
  attribute :ramp_claim_id
  attribute :rating_issue_associated_at
  attribute :split_issue_status
  attribute :unidentified_issue_text
  attribute :untimely_exemption
  attribute :untimely_exemption_notes
  attribute :updated_at
  attribute :vacols_id
  attribute :vacols_sequence_id
  attribute :verified_unidentified_issue
  attribute :veteran_participant_id

  attribute :decision_issues do |request_issue|
    request_issue.decision_issues do |di|
      ::Api::V3::External::DecisionIssueSerializer.new(di)
    end
  end
end
