class AddIndexDecisionIssueToRequestIssue < Caseflow::Migration
  def change
    # Enable efficient queries when calling di.request_issues
    add_safe_index(:request_decision_issues, [:decision_issue_id, :request_issue_id],
                   unique: true, algorithm: :concurrently,
                   :name => 'index_on_decision_issue_id_and_request_issue_id'
    )
  end
end
