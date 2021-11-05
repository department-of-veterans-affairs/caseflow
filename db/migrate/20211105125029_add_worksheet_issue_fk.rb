class AddWorksheetIssueFk < Caseflow::Migration
  def change
    add_foreign_key "worksheet_issues", "appeals", validate: false
  end
end
