# frozen_string_literal: true

class Intake::IssueModificationRequestSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :status
  attribute :request_type
  attribute :remove_original_issue
  attribute :nonrating_issue_category
  attribute :nonrating_issue_description
  attribute :benefit_type
  attribute :decision_date
  attribute :decided_at
  attribute :decision_reason
  attribute :request_reason
  # This should maybe be a serialized request issue instead of an id not sure
  attribute :request_issue_id
end
