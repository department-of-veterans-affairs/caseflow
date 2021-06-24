class AddHearingsRelatedForeignKeys < Caseflow::Migration
  def change
    add_foreign_key "hearing_issue_notes", "request_issues", validate: false
    add_foreign_key "hearing_issue_notes", "hearings", validate: false

    add_foreign_key "hearings", "hearing_days", validate: false
    add_foreign_key "transcriptions", "hearings", validate: false
    add_foreign_key "virtual_hearing_establishments", "virtual_hearings", validate: false
  end
end
