# frozen_string_literal: true

class Intake::AppealIntakeSerializer < Intake::DecisionReviewIntakeSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :docket_type do |object|
    object.detail.docket_type
  end

  attribute :homelessness do |object|
    object.detail.homelessness
  end

  attribute :original_hearing_request_type do |object|
    object.detail.original_hearing_request_type
  end
end
