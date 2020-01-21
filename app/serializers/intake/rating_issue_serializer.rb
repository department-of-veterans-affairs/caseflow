# frozen_string_literal: true

class Intake::RatingIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_id(&:reference_id)

  attribute :participant_id
  attribute :reference_id
  attribute :decision_text
  attribute :promulgation_date
  attribute :profile_date
  attribute :ramp_claim_id
  attribute :rba_contentions_data
  attribute :diagnostic_code
  attribute :benefit_type
  attribute :associated_end_products do |object|
    object.associated_end_products.map(&:serialize)
  end
end
