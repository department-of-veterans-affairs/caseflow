# frozen_string_literal: true

class IssueModificationRequest < CaseflowRecord
  has_paper_trail on: [:update, :destroy]

  belongs_to :request_issue
  belongs_to :decision_review, polymorphic: true
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :requestor, presence: true

  before_create :open_issue_modification_request, if: :not_addition?

  before_save :set_decided_at

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  enum request_type: {
    addition: "addition",
    removal: "removal",
    modification: "modification",
    withdrawal: "withdrawal"
  }

  def serialize
    Intake::IssueModificationRequestSerializer.new(self).serializable_hash[:data][:attributes]
  end

  private

  def open_issue_modification_request
    if assigned? && !!request_issue && request_issue.issue_modification_requests.any?(&:assigned?)
      errors.add("Cannot exceed more than one issue modification request at a time")
    end
  end

  def set_decided_at
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end

  def not_addition?
    request_type != "addition"
  end
end
