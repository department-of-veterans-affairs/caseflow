# frozen_string_literal: true

class Intake::HigherLevelReviewSerializer < Intake::ClaimReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :informal_conference
  attribute :same_office
  attribute :form_type do
    "higher_level_review"
  end
end
