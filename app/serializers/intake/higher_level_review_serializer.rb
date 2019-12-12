# frozen_string_literal: true

class Intake::HigherLevelReviewSerializer < Intake::ClaimReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :informalConference, &:informal_conference
  attribute :sameOffice, &:same_office

  attribute :formType do
    "higher_level_review"
  end
end
