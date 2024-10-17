# frozen_string_literal: true

class LegacyIssue < CaseflowRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin
  has_one :event_record, as: :evented_record

  validates :request_issue, presence: true

  def from_decision_review_created_event?
    # refer back to the associated Intake to see if both objects came from DRCE
    request_issue&.from_decision_review_created_event?
  end
end
