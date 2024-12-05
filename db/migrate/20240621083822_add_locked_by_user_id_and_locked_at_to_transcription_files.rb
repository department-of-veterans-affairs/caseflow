class AddLockedByUserIdAndLockedAtToTranscriptionFiles < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def up
    add_column :transcription_files, :locked_by_id, :bigint, comment: "ID of user who locked the record"
    add_column :transcription_files, :locked_at, :datetime, comment: "Locked record timeout field"
    add_foreign_key :transcription_files, :users, column: "locked_by_id", validate: false
    add_safe_index :transcription_files, [:locked_by_id, :locked_at], name: "index_transcription_files_locked_by_id_locked_at"
  end

  def down
    remove_index :transcription_files, name: "index_transcription_files_locked_by_id_locked_at"
    remove_foreign_key :transcription_files, :users, column: "locked_by_id"
    remove_column :transcription_files, :locked_at
    remove_column :transcription_files, :locked_by_id
  end
end
