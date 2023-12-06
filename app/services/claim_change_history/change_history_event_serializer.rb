# frozen_string_literal: true

# TODO: Should all this be named spaced? Probably.
class ChangeHistoryEventSerializer
  include FastJsonapi::ObjectSerializer

  set_id { SecureRandom.uuid }
  attribute :taskID, &:task_id
  attribute :eventType, &:event_type
  attribute :readableEventType, &:readable_event_type
  attribute :eventUserName, &:readable_user_name
  attribute :claimantName, &:claimant_name
  attribute :eventDate, &:event_date
  attribute :benefitType, &:benefit_type
  attribute :issueType, &:issue_type
  attribute :issueDescription, &:issue_description
  attribute :decisionDate, &:decision_date
  attribute :disposition, &:disposition
  attribute :dispositionDate, &:disposition_date
  attribute :decisionDescription, &:decision_description
  attribute :withdrawlRequestDate, &:withdrawal_request_date
end
