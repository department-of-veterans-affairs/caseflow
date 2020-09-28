class AddRequestIssueTypeToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :request_issue_type, :string, default: :request_isssue, comment: "Determines whether the issue is a rating issue or a nonrating issue"
  end
end
