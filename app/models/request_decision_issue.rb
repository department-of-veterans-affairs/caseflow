# frozen_string_literal: true

class RequestDecisionIssue < CaseflowRecord
  belongs_to :request_issue
  belongs_to :decision_issue

  validates :request_issue, :decision_issue, presence: true

  # We are using default scope here because we'd like to soft delete decision issues
  # for debugging purposes and to make it easier for developers to filter soft deleted records
  default_scope { where(deleted_at: nil) }
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: request_decision_issues
#
#  id                :bigint           not null, primary key
#  deleted_at        :datetime         indexed
#  created_at        :datetime         not null
#  updated_at        :datetime         not null, indexed
#  decision_issue_id :integer          indexed => [request_issue_id], indexed => [request_issue_id]
#  request_issue_id  :integer          indexed => [decision_issue_id], indexed => [decision_issue_id]
#
# Foreign Keys
#
#  fk_rails_4a834a8efc  (decision_issue_id => decision_issues.id)
#  fk_rails_7df6e1eaab  (request_issue_id => request_issues.id)
#
