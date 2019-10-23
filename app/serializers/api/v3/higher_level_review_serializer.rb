# frozen_string_literal: true

class Api::V3::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  set_id :uuid
  self.record_type = "HigherLevelReview"

  attribute :status, &:fetch_status

  attributes :aoj, :description, :benefit_type, :receipt_date, :informal_conference,
             :same_office, :legacy_opt_in_approved, :alerts, :events
  attribute :program_area, &:program

  has_one :veteran, &:veteran

  has_one :claimant do |object|
    object.claimants.first
  end

  has_many :decision_issues, &:fetch_all_decision_issues

  has_many :request_issues do |object|
    object.request_issues.includes(
      :decision_review, :contested_decision_issue
    ).active_or_ineligible_or_withdrawn
  end
end
