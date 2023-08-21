# frozen_string_literal: true

class Intake::RatingIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_id(&:reference_id)

  attribute :associated_end_products do |object|
    object.associated_end_products.map(&:serialize)
  end
  attribute :benefit_type
  attribute :decision_text
  attribute :diagnostic_code
  attribute :participant_id
  attribute :percent_number
  attribute :profile_date
  attribute :promulgation_date
  attribute :ramp_claim_id
  attribute :rba_contentions_data
  attribute :reference_id
  attribute :subject_text
  # attribute :special_issues
end
