class AddAppealStreamSnapshotFKs < Caseflow::Migration
  def change
    add_foreign_key "hearing_appeal_stream_snapshots", "legacy_appeals", column: "appeal_id", validate: false    
    add_foreign_key "hearing_appeal_stream_snapshots", "legacy_hearings", column: "hearing_id", validate: false  
  end
end
