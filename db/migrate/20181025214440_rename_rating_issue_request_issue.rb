class RenameRatingIssueRequestIssue < ActiveRecord::Migration[5.1]
  def change
    rename_column :rating_issues, :request_issue_id, :source_request_issue_id
  end
end
