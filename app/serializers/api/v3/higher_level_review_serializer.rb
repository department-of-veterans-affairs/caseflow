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

  # disable SymbolProc because these relationships aren't Rails relationships
  # rubocop:disable Style/SymbolProc

  has_one :veteran do |higher_level_review|
    higher_level_review.veteran
  end

  has_one :claimant do |higher_level_review|
    higher_level_review.claimants.first
  end

  has_many :decision_issues do |higher_level_review|
    higher_level_review.fetch_all_decision_issues
  end

  has_many :request_issues do |higher_level_review|
    higher_level_review.request_issues.includes(
      :decision_review, :contested_decision_issue
    ).active_or_ineligible_or_withdrawn
  end
  # rubocop:enable Style/SymbolProc
end
