class ValidateDecisionIssueEndProductEstablishmentForeignKeysForRequestIssues < Caseflow::Migration
  def change
    validate_foreign_key "request_issues", column: "contested_decision_issue_id"
    validate_foreign_key "request_issues", "end_product_establishments"
  end
end
