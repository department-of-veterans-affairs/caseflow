class ValidateWorksheetIssueFk < Caseflow::Migration
  def change
    validate_foreign_key "worksheet_issues", "appeals"
  end
end
