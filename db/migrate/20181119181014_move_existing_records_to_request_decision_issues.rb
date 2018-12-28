class MoveExistingRecordsToRequestDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    DecisionIssue.all.find_each do |decision_issue|
  	  RequestDecisionIssue.find_or_create_by(request_issue: decision_issue.source_request_issue, decision_issue: decision_issue)
    end
  end
end
