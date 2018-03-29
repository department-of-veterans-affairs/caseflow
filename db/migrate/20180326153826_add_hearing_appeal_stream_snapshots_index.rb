class AddHearingAppealStreamSnapshotsIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index(:hearing_appeal_stream_snapshots, [:hearing_id, :appeal_id], unique: true,
      algorithm: :concurrently, name: 'index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids')
  end
end
