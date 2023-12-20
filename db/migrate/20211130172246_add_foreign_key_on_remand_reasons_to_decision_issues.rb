class AddForeignKeyOnRemandReasonsToDecisionIssues < Caseflow::Migration
  def change
    add_foreign_key "remand_reasons", "decision_issues", validate: false
  end
end
