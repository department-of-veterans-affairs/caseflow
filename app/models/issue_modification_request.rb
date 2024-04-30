# frozen_string_literal: true

class IssueModificationRequest < CaseflowRecord
  belongs_to :request_issue
  belongs_to :decision_review, polymorphic: true
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  enum request_type: {
    addition: "Addition",
    removal: "Removal",
    modification: "Modification",
    withdrawal: "Withdrawal"
  }
end
