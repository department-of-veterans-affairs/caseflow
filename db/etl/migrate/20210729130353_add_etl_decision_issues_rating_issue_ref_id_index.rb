class AddEtlDecisionIssuesRatingIssueRefIdIndex < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_safe_index :decision_issues, :rating_issue_reference_id, algorithm: :concurrently
  end
end
