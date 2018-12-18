class AddParentRequestIdToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :parent_request_issue_id, :integer
  end
end
