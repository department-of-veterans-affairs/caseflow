class ValidateRequestIssuesRelatedForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key "legacy_issue_optins", "request_issues"
    validate_foreign_key "legacy_issues", "request_issues"
    validate_foreign_key "request_decision_issues", "request_issues"
    validate_foreign_key "request_decision_issues", "decision_issues"
    validate_foreign_key "request_issues", column: "corrected_by_request_issue_id"
    validate_foreign_key "request_issues", column: "ineligible_due_to_id"
  end
end
