class ValidateAppealStreamSnapshotFKs < Caseflow::Migration
  def change
  	validate_foreign_key "hearing_appeal_stream_snapshots", "legacy_appeals"    
    validate_foreign_key "hearing_appeal_stream_snapshots", "legacy_hearings"
  end
end
