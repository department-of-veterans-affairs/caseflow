class AddForeignKeysForRequestIssues < Caseflow::Migration
  def change
    add_foreign_key "legacy_issue_optins", "request_issues", validate: false
    add_foreign_key "legacy_issues", "request_issues", validate: false
    add_foreign_key "request_decision_issues", "request_issues", validate: false
    add_foreign_key "request_decision_issues", "decision_issues", validate: false
    add_foreign_key "request_issues", "request_issues", column: "corrected_by_request_issue_id", validate: false
    add_foreign_key "request_issues", "request_issues", column: "ineligible_due_to_id", validate: false
  end
end
