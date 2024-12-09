class RemoveEtlDecisionIssuesIndex < Caseflow::Migration
  def change
    remove_index(:decision_issues,
      column: ["rating_issue_reference_id", "disposition", "participant_id"],
      name: "index_decision_issues_uniq"
    ) if index_exists?(:decision_issues,
      ["rating_issue_reference_id", "disposition", "participant_id"],
      unique: true,
      name: "index_decision_issues_uniq")
  end
end
