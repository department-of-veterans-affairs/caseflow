class RemoveSourceRequestIssueId < ActiveRecord::Migration[5.1]
  def change
  	remove_column :decision_issues, :source_request_issue_id
  end
end
