class AddTranscriptionIdToTranscriptionFiles < Caseflow::Migration

  def change
    add_column :transcription_files, :transcription_id, :bigint, comment: "ID of the associated transcription record"

    add_index :transcription_files, :transcription_id, algorithm: :concurrently
  end
end
