class ValidateForeignKeyOnRemandReasonsToDecisionIssues < Caseflow::Migration
  def change
    validate_foreign_key "remand_reasons", column: "decision_issue_id"
  end
end
