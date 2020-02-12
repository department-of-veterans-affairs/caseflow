# frozen_string_literal: true

class LegacyIssue < ApplicationRecord
  belongs_to :request_issue
  has_one :legacy_issue_optin

  validates :request_issue, presence: true
end
