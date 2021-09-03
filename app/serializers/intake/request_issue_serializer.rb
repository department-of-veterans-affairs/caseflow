# frozen_string_literal: true

class Intake::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :rating_issue_reference_id, &:contested_rating_issue_reference_id
  attribute :rating_issue_profile_date, &:contested_rating_issue_profile_date
  attribute :rating_decision_reference_id, &:contested_rating_decision_reference_id
  attribute :description
  attribute :contention_text
  attribute :approx_decision_date, &:approx_decision_date_of_issue_being_contested
  attribute :category, &:nonrating_issue_category
  attribute :notes
  attribute :is_unidentified
  attribute :ramp_claim_id
  attribute :vacols_id
  attribute :vacols_sequence_id
  attribute :ineligible_reason
  attribute :ineligible_due_to_id
  attribute :decision_review_title, &:review_title
  attribute :title_of_active_review
  attribute :contested_decision_issue_id
  attribute :withdrawal_date
  attribute :contested_issue_description
  attribute :end_product_code
  attribute :verified_unidentified_issue
  attribute :editable, &:editable?
  attribute :exam_requested, &:exam_requested?
  attribute :vacols_issue do |object|
    object.vacols_issue.try(:intake_attributes)
  end
  attribute :end_product_cleared do |object|
    object.end_product_establishment&.status_cleared?
  end
  attribute :benefit_type
end
