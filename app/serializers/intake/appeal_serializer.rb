# frozen_string_literal: true

class Intake::AppealSerializer < Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :docket_type
  attribute :is_outcoded, &:outcoded?
  attribute :form_type do
    "appeal"
  end
  attribute :type
  attribute :vacate_type, if: proc { |appeal| appeal.vacate? }
end
