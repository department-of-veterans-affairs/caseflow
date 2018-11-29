class RenameIneligibleRequestIssue < ActiveRecord::Migration[5.1]
  def change
    rename_column :request_issues, :ineligible_request_issue_id, :ineligible_due_to_id
  end
end
