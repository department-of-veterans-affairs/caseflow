class AddVeteranIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :veterans, :ssn, algorithm: :concurrently
    add_index :veterans, :participant_id, algorithm: :concurrently
  end
end
