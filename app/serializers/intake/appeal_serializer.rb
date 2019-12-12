# frozen_string_literal: true

class Intake::AppealSerializer < Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :docket_type, &:docket_type
  attribute :is_outcoded, &:outcoded?

  attribute :formType do
    "appeal"
  end
end
