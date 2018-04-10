class IndexDocketTracersOnDocketSnapshotIdAndMonth < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :docket_tracers, [:docket_snapshot_id, :month], unique: true, algorithm: :concurrently
  end
end
