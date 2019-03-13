class RemoveParentRequestIssueIdFromRequestIssues < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :request_issues, :parent_request_issue_id, :integer }
  end
end
