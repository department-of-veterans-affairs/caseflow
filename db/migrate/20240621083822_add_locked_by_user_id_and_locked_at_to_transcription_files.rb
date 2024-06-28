class AddLockedByUserIdAndLockedAtToTranscriptionFiles < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_column :transcription_files, :locked_by_id, :bigint, comment: "ID of user who locked the record"
    add_column :transcription_files, :locked_at, :datetime, comment: "Locked record timeout field"

    add_foreign_key :transcription_files, :users, column: "locked_by_id", validate: false
    add_safe_index :transcription_files, [:locked_by_id, :locked_at], name: "index_transcription_files_locked_by_id_locked_at"
  end
end
