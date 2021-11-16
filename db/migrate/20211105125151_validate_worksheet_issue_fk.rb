class ValidateWorksheetIssueFk < Caseflow::Migration
  def change
    validate_foreign_key "worksheet_issues", column: "appeal_id"
  end
end
