class AddClaimantParticipantIdIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index(:claimants, :participant_id, algorithm: :concurrently)
  end
end
