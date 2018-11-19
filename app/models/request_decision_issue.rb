class RequestDecisionIssue < ApplicationRecord
  belongs_to :request_issue
  belongs_to :decision_issue

  validates :request_issue, :decision_issue, presence: true
  validates :request_issue, uniqueness:
    { scope: :decision_issue, message: "Combination of request issue and decision issue must be unique" }
end
