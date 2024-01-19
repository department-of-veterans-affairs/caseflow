# frozen_string_literal: true

class LegacyIssue < CaseflowRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin
  has_many :event_records, as: :backfill_record

  validates :request_issue, presence: true
end
