class AddForeignKeysForAppeals < Caseflow::Migration
  def change
    add_foreign_key "special_issue_lists", "appeals", validate: false

  end
end
