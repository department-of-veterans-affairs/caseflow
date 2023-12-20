class AddWorksheetIssueFk < Caseflow::Migration
  def change
    add_foreign_key "worksheet_issues", "legacy_appeals", column: "appeal_id", validate: false
  end
end
