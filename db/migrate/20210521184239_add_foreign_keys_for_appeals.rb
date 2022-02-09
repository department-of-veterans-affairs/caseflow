class AddForeignKeysForAppeals < Caseflow::Migration
  def change
    add_foreign_key "dispatch_tasks", "legacy_appeals", column: "appeal_id", validate: false
    add_foreign_key "legacy_hearings", "legacy_appeals", column: "appeal_id", validate: false
    add_foreign_key "hearings", "appeals", column: "appeal_id", validate: false
    add_foreign_key "hearing_email_recipients", "appeals", column: "appeal_id", validate: false
  end
end
