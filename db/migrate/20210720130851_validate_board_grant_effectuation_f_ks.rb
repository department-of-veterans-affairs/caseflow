class ValidateBoardGrantEffectuationFKs < Caseflow::Migration
  def change
    validate_foreign_key "board_grant_effectuations", "appeals"
    validate_foreign_key "board_grant_effectuations", "decision_documents"
    validate_foreign_key "board_grant_effectuations", "end_product_establishments"
    validate_foreign_key "board_grant_effectuations", column: "granted_decision_issue_id"
  end
end
