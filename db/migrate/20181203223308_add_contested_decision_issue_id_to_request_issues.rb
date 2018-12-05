class AddContestedDecisionIssueIdToRequestIssues < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  safety_assured

  def change
    add_column :request_issues, :contested_decision_issue_id, :integer
    add_index :request_issues, :contested_decision_issue_id, algorithm: :concurrently
  end
end
