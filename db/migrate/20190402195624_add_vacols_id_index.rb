class AddVacolsIdIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :legacy_hearings, :vacols_id, algorithm: :concurrently
  end
end
