class AddCommentsToRequestDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:request_decision_issues, "Bridge table to match RequestIssues to DecisionIssues.")
    
    change_column_comment(:request_decision_issues, :created_at, "Automatic timestamp when row was created.")

    change_column_comment(:request_decision_issues, :decision_issue_id, "The ID of the decision issue connected.")

    change_column_comment(:request_decision_issues, :request_issue_id, "The ID of the request issue connected.")

    change_column_comment(:request_decision_issues, :updated_at, "Automatically populated when the record is updated.")
  end
end
