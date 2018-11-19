class AddUniqIndexToRequestDecisionIssues < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
  	add_index :request_decision_issues, [:request_issue_id, :decision_issue_id], unique: true, algorithm: :concurrently, :name => 'index_on_request_issue_id_and_decision_issue_id'
  end
end
