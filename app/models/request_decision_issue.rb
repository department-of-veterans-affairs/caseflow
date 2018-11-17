class RequestDecisionIssue < ApplicationRecord
  belongs_to :request_issue
  belongs_to :decision_issue
end
