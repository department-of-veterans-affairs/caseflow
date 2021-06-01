class RemoveRatingIssueIndexFromDecisionIssues < Caseflow::Migration
  def up
    remove_index :decision_issues, column: ["rating_issue_reference_id", "disposition", "participant_id"]
    add_safe_index :decision_issues, :rating_issue_reference_id
    change_column_comment(:decision_issues, :rating_issue_reference_id, "Identifies the specific issue on the rating that resulted from the decision issue (a rating issue can be connected to multiple contentions).")
  end

  def down
    remove_index :decision_issues, name: "index_decision_issues_on_rating_issue_reference_id"
    add_safe_index :decision_issues, ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_by_disposition_and_ref_id", algorithm: :concurrently
    change_column_comment(:decision_issues, :rating_issue_reference_id, "Identifies the specific issue on the rating that resulted from the decision issue (a rating can have multiple issues).")
  end
end
