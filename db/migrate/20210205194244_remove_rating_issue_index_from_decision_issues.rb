class RemoveRatingIssueIndexFromDecisionIssues < Caseflow::Migration
  def change
  	remove_index :decision_issues, column: ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_uniq_by_disposition_and_ref_id", unique: true
  end
end
