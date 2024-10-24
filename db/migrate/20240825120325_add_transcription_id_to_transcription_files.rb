class AddTranscriptionIdToTranscriptionFiles < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    add_column :transcription_files, :transcription_id, :bigint, comment: "ID of the associated transcription record"

    add_safe_index :transcription_files, :transcription_id, algorithm: :concurrently
  end
end
