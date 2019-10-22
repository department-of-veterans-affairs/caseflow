class Api::V3::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = 'RequestIssue'

  attributes :diagnostic_code, :description, :contention_text, :notes,
    :is_unidentified, :ramp_claim_id, :ineligible_reason,
    :ineligible_due_to_id, :withdrawal_date, :contested_issue_description,
    :end_product_code, :title_of_active_review

  attribute :active do |object|
    object.closed_at.nil? && object.ineligible_reason.nil?
  end

  attribute :status_description, &:api_status_description
  attribute :rating_issue_id, &:contested_rating_issue_reference_id
  attribute :rating_issue_profile_date, &:contested_rating_issue_profile_date
  attribute :rating_decision_id, &:contested_rating_decision_reference_id
  attribute :approx_decision_date, &:approx_decision_date_of_issue_being_contested
  attribute :category, &:nonrating_issue_category
  attribute :legacy_appeal_id, &:vacols_id
  attribute :legacy_appeal_issue_id, &:vacols_sequence_id
  attribute :decision_review_title, &:review_title # REVIEW do we want to rename this?
  attribute :decision_issue_id, &:contested_decision_issue_id
  attribute :end_product_cleared do |object|
    object.end_product_establishment&.status_cleared?
  end
end
