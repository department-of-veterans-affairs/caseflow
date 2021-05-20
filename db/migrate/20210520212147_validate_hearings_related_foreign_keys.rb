class ValidateHearingsRelatedForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key "hearing_issue_notes", "request_issues"
    validate_foreign_key "hearing_issue_notes", "hearings"

    validate_foreign_key "hearings", "hearing_days"
    validate_foreign_key "transcriptions", "hearings"
    validate_foreign_key "virtual_hearing_establishments", "virtual_hearings"
  end
end
