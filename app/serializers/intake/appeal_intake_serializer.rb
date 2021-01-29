# frozen_string_literal: true

class Intake::AppealIntakeSerializer < Intake::DecisionReviewIntakeSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :docket_type do |object|
    object.detail.docket_type
  end
end
