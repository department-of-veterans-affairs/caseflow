class Api::V3::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attributes :diagnostic_code, :rating_issue_id,
    :rating_issue_profile_date, :rating_decision_reference_id, :description,
    :contention_text, :approx_decision_date, :category, :notes, :is_unidentified,
    :ramp_claim_id, :legacy_appeal_id, :legacy_appeal_issue_id, :ineligible_reason,
    :ineligible_due_to_id, :decision_review_title, :title_of_active_review,
    :decision_issue_id, :withdrawal_date, :contested_issue_description,
    :end_product_cleared, :end_product_code

  attribute :active do |object|
    object.closed_at.nil? && object.ineligible_reason.nil?
  end

  attribute :status_description, &:api_status_description
end
