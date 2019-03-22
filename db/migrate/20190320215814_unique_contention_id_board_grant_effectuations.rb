class UniqueContentionIdBoardGrantEffectuations < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :board_grant_effectuations, :contention_reference_id, unique: true, algorithm: :concurrently
  end
end
