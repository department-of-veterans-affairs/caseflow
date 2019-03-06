# frozen_string_literal: true

class RequestDecisionIssue < ApplicationRecord
  belongs_to :request_issue
  belongs_to :decision_issue

  validates :request_issue, :decision_issue, presence: true
end
