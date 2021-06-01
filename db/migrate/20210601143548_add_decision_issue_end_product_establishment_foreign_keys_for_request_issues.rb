class AddDecisionIssueEndProductEstablishmentForeignKeysForRequestIssues < Caseflow::Migration
  def change
  	add_foreign_key "request_issues", "decision_issues", column: "contested_decision_issue_id", validate: false    
    add_foreign_key "request_issues", "end_product_establishments", validate: false
  end
end
