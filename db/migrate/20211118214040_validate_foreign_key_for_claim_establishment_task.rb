class ValidateForeignKeyForClaimEstablishmentTask < Caseflow::Migration
  def change
    validate_foreign_key "claim_establishments", column: "task_id"
  end
end
