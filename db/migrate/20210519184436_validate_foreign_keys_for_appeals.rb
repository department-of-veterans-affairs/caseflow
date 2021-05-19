class ValidateForeignKeysForAppeals < Caseflow::Migration
  def change
    validate_foreign_key "special_issue_lists", "appeals"
  end
end
