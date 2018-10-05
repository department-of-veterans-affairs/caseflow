class AddIndexOnParentRequestIssueId < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :request_issues, :parent_request_issue_id, algorithm: :concurrently
  end
end
