class AddTranscriptionIdToTranscriptionFiles < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :transcription_files, :transcription_id, :bigint, comment: "ID of the associated transcription record"
    add_index :transcription_files, :transcription_id, algorithm: :concurrently, name: "index_transcription_files_on_transcription_id"
  end
end
