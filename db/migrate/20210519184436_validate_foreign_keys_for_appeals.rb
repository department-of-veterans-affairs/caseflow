class ValidateForeignKeysForAppeals < Caseflow::Migration
  def change
    validate_foreign_key "dispatch_tasks", column: "appeal_id"
    validate_foreign_key "legacy_hearings", column: "appeal_id"
  end
end
