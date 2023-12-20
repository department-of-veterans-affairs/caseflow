class ValidateForeignKeyOnAdvanceOnDocketMotionsToPersons < Caseflow::Migration
  def change
    validate_foreign_key "advance_on_docket_motions", column: "person_id"
  end
end
