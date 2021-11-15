class ValidateForeignKeyForClaimEstablishmentTask < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key "claim_establishments", column: "task_id"
  end
end
