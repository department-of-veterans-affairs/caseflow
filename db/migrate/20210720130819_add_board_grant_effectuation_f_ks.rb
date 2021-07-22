class AddBoardGrantEffectuationFKs < Caseflow::Migration
  def change
    add_foreign_key "board_grant_effectuations", "appeals", validate: false
    add_foreign_key "board_grant_effectuations", "decision_documents", validate: false
    add_foreign_key "board_grant_effectuations", "end_product_establishments", validate: false
    add_foreign_key "board_grant_effectuations", "decision_issues", column: "granted_decision_issue_id", validate: false
  end
end
