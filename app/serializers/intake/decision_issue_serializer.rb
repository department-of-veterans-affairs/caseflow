# frozen_string_literal: true

class Intake::DecisionIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  # converts ui_hash into a serializer
  attribute :id
  attribute :description
  attribute :disposition
  attribute :approx_decision_date
  attribute :request_issue_id do |object|
    object.request_issues&.first&.id
  end
  attribute :mst_status
  attribute :pact_status
end
