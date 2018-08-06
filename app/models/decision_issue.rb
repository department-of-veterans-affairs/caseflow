class DecisionIssue < ApplicationRecord
	validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS.keys.map(&:to_s) }
  belongs_to :request_issue
end