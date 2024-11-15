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
  attribute :request_issue_id
  attribute :request_issue
  attribute :requestor
  attribute :decider
  attribute :withdrawal_date
end
