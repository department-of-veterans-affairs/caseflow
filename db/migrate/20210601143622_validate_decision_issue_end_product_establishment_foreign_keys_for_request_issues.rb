class ValidateDecisionIssueEndProductEstablishmentForeignKeysForRequestIssues < ActiveRecord::Migration[5.2]
  def change
  	validate_foreign_key "request_issues", column: "contested_decision_issue_id"
  	validate_foreign_key "request_issues", "end_product_establishments"
  end
end
