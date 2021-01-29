# frozen_string_literal: true

class Intake::RampRefilingIntakeSerializer < Intake::IntakeSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :option_selected do |object|
    object.detail.option_selected
  end

  attribute :receipt_date do |object|
    object.detail.receipt_date
  end

  attribute :election_receipt_date do |object|
    object.detail.election_receipt_date
  end

  attribute :appeal_docket do |object|
    object.detail.appeal_docket
  end

  attribute :issues do |object|
    object.ramp_elections_with_decisions.map(&:issues).flatten.map(&:serialize)
  end

  attribute :end_product_description do |object|
    object.detail.end_product_description
  end
end
