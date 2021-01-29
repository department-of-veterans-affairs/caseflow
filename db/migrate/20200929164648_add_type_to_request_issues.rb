class AddTypeToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :type, :string, default: "RequestIssue", comment: "Determines whether the issue is a rating issue or a nonrating issue"
  end
end
