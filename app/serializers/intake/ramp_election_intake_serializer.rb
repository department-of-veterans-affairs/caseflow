# frozen_string_literal: true

class Intake::RampElectionIntakeSerializer < Intake::IntakeSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :notice_date do |object|
    object.ramp_election.notice_date
  end

  attribute :option_selected do |object|
    object.ramp_election.option_selected
  end

  attribute :receipt_date do |object|
    object.ramp_election.receipt_date
  end

  attribute :end_product_description do |object|
    object.ramp_election.end_product_description
  end

  attribute :appeals, &:serialized_appeal_issues
end
