# frozen_string_literal: true

class Intake::AppealSerializer < Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :docketType, &:docket_type
  attribute :isOutcoded, &:outcoded?

  attribute :formType do
    "appeal"
  end
end
