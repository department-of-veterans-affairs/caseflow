# frozen_string_literal: true

class Api::V3::DecisionIssueSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower
  set_type "DecisionIssue"

  attributes :approx_decision_date, :decision_text, :description, :disposition
  attribute :finalized, &:finalized?
end
