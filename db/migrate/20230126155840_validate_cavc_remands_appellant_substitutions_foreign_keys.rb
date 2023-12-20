class ValidateCavcRemandsAppellantSubstitutionsForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key :cavc_remands_appellant_substitutions, column: "cavc_remand_id"
    validate_foreign_key :cavc_remands_appellant_substitutions, column: "appellant_substitution_id"
    validate_foreign_key :cavc_remands_appellant_substitutions, column: "created_by_id"
    validate_foreign_key :cavc_remands_appellant_substitutions, column: "updated_by_id"
  end
end
