class AddUniqueConstraintHearingsVacolsIds < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    remove_index :legacy_hearings, :vacols_id
    add_index :legacy_hearings, :vacols_id, unique: true, algorithm: :concurrently
  end
end
