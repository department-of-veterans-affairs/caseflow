class AddIndexToRequestIssuesReferenceId < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_index :request_issues, :reference_id, name: "index_request_issues_on_reference_id", algorithm: :concurrently
  end
end
