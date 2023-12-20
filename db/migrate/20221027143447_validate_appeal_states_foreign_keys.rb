class ValidateAppealStatesForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key :appeal_states, column: "updated_by_id"
    validate_foreign_key :appeal_states, column: "created_by_id"
  end
end
