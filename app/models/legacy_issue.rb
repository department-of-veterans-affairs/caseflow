# frozen_string_literal: true

class LegacyIssue < CaseflowRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin
  has_one :event_record, as: :backfill_record

  validates :request_issue, presence: true
end
