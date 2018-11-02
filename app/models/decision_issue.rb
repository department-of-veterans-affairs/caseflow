class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) }, allow_nil: true
  belongs_to :source_request_issue, class_name: "RequestIssue"
end
