class AddRequestIssueTypeToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :request_issue_type, :string, default: "RequestIssue", comment: "Determines whether the issue is a rating issue or a nonrating issue"
  end
end
