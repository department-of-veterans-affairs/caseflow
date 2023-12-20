class AddForeignKeysOnCavcRemandsAppellantSubstitutions < Caseflow::Migration
  def change
    add_foreign_key :cavc_remands_appellant_substitutions, :users, column: "updated_by_id", validate: false
    add_foreign_key :cavc_remands_appellant_substitutions, :users, column: "created_by_id", validate: false

    add_foreign_key :cavc_remands_appellant_substitutions, :cavc_remands, column: "cavc_remand_id", validate: false

    add_foreign_key :cavc_remands_appellant_substitutions, :appellant_substitutions, column: "appellant_substitution_id", validate: false
  end
end
