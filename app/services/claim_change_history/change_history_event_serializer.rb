# frozen_string_literal: true

class ChangeHistoryEventSerializer
  include FastJsonapi::ObjectSerializer

  set_id { SecureRandom.uuid }
  attribute :taskID, &:task_id
  attribute :eventType, &:event_type
  attribute :eventUser, &:readable_user_name
  attribute :eventDate, &:event_date
  attribute :claimType, &:readable_claim_type
  attribute :readableEventType, &:readable_event_type
  attribute :claimantName, &:claimant_name

  attribute :details do |object|
    {
      benefitType: object.benefit_type,
      issueType: object.issue_type,
      issueDescription: object.issue_description,
      decisionDate: object.decision_date,
      disposition: object.disposition,
      decisionDescription: object.decision_description,
      dispositionDate: object.disposition_date,
      withdrawalRequestDate: object.withdrawal_request_date
    }
  end
end
