class AddDecisionIssueIndexes < Caseflow::Migration
  def change
    add_safe_index :decision_issues, :deleted_at
    add_safe_index :decision_issues, [:decision_review_id, :decision_review_type], name: :index_decision_issues_decision_review
  end
end
