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

  attribute :modificationRequestDetails do |object|
    {
      requestType: object.request_type,
      benefitType: object.benefit_type,
      newIssueType: object.new_issue_type,
      newIssueDescription: object.new_issue_description,
      newDecisionDate: object.new_decision_date,
      modificationRequestReason: object.modification_request_reason,
      issueModificationRequestWithdrawalDate: object.issue_modification_request_withdrawal_date,
      removeOriginalIssue: object.remove_original_issue,
      issueModificationRequestStatus: object.issue_modification_request_status,
      requestor: object.requestor,
      decider: object.decider,
      decidedAtDate: object.decided_at_date,
      decisionReason: object.decision_reason,
      previousIssueType: object.previous_issue_type,
      previousIssueDescription: object.previous_issue_description,
      previousDecisionDate: object.previous_decision_date,
      previousModificationRequestReason: object.previous_modification_request_reason,
      previousWithdrawalDate: object.previous_withdrawal_date
    }
  end
end
