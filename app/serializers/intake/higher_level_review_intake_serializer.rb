# frozen_string_literal: true

class Intake::HigherLevelReviewIntakeSerializer < Intake::ClaimReviewIntakeSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :same_office do |object|
    object.detail.same_office
  end

  attribute :informal_conference do |object|
    object.detail.informal_conference
  end
end
