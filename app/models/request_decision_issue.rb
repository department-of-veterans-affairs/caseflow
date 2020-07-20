# frozen_string_literal: true

class RequestDecisionIssue < CaseflowRecord
  belongs_to :request_issue
  belongs_to :decision_issue

  validates :request_issue, :decision_issue, presence: true

  # We are using default scope here because we'd like to soft delete decision issues
  # for debugging purposes and to make it easier for developers to filter soft deleted records
  default_scope { where(deleted_at: nil) }
end
