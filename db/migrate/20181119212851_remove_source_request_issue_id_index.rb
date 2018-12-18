class RemoveSourceRequestIssueIdIndex < ActiveRecord::Migration[5.1]
  def change
  	remove_index :decision_issues, column: :source_request_issue_id
  	change_column_null :decision_issues, :source_request_issue_id, true
  end
end
