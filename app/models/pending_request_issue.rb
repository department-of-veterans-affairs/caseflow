# frozen_string_literal: true

class PendingRequestIssue < CaseflowRecord

  belongs_to :request_issue
  belongs_to :decision_review, polymorphic: true

  enum status: {
    pending: "pending",
    accepted: "accepted",
    rejected: "rejected",
    cancelld: "cancelled"
  }
end
