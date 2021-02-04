class RemoveUniqueRatingIssueIndexFromDecisionIssues < Caseflow::Migration
   def up
  	add_safe_index :decision_issues, ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_by_disposition_and_ref_id"
  end

  def down
  	remove_index :decision_issues, name: "decision_issues_uniq_by_disposition_and_ref_id", unique: true
  end
end
