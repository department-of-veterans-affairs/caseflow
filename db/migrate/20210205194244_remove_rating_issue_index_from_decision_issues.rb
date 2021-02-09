class RemoveRatingIssueIndexFromDecisionIssues < Caseflow::Migration
  def up
    remove_index :decision_issues, column: ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_uniq_by_disposition_and_ref_id", unique: true
    add_safe_index :decision_issues, :rating_issue_reference_id
  end

  def down
    # Removing uniqueness index, do not want to rollback
  end
end
