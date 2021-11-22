class AddForeignKeyForClaimEstablishmentTask < Caseflow::Migration
  def change
    add_foreign_key "claim_establishments", "dispatch_tasks", column: "task_id", validate: false
  end
end
