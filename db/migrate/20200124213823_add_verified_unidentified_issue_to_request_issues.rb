class AddVerifiedUnidentifiedIssueToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :verified_unidentified_issue, :boolean
  end
end
