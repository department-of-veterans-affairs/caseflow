# frozen_string_literal: true

class Api::V3::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = "RequestIssue"

  attributes :diagnostic_code, :description, :contention_text, :notes,
             :is_unidentified, :ramp_claim_id, :withdrawal_date,
             :contested_issue_description, :end_product_code

  attribute :active do |request_issue|
    request_issue.closed_at.nil? && request_issue.ineligible_reason.nil?
  end

  attribute :ineligible do |request_issue|
    unless request_issue.ineligible_due_to_id.nil?
      {
        dueToId: request_issue.ineligible_due_to_id,
        reason: request_issue.ineligible_reason,
        titleOfActiveReview: request_issue.title_of_active_review
      }
    end
  end

  attribute :status_description, &:api_status_description
  attribute :rating_issue_id, &:contested_rating_issue_reference_id
  attribute :rating_issue_profile_date, &:contested_rating_issue_profile_date
  attribute :rating_decision_id, &:contested_rating_decision_reference_id
  attribute :approx_decision_date, &:approx_decision_date_of_issue_being_contested
  attribute :category, &:nonrating_issue_category
  attribute :legacy_appeal_id, &:vacols_id
  attribute :legacy_appeal_issue_id, &:vacols_sequence_id
  attribute :decision_review_title, &:review_title
  attribute :decision_issue_id, &:contested_decision_issue_id
  attribute :end_product_cleared do |request_issue|
    request_issue.end_product_establishment&.status_cleared?
  end
end
