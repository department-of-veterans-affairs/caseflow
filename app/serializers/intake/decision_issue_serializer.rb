class DecisionIssueSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, &:id
  attribute :requestIssueId, &:request_issues&.first&.id
  attribute :description, &:description
  attribute :disposition, &:disposition
  attribute :approxDecisionDate, &:disposition
end