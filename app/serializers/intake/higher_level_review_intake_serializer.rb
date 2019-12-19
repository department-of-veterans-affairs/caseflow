# frozen_string_literal: true

class Intake::HigherLevelReviewIntakeSerializer < Intake::ClaimReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :same_office, &:same_office

  attribute :informal_conference, &:informal_conference
end
