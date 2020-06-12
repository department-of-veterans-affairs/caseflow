class BackfillClaimantType < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    Claimant.unscoped.in_batches do |relation|
      relation.update_all type: "Claimant"
      sleep(0.1)
    end
  end
end
