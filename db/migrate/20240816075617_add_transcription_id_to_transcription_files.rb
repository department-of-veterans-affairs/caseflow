class AddTranscriptionIdToTranscriptionFiles < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_column :transcription_files, :transcription_id, :bigint, comment: 'ID of the transcription record'
    add_index :transcription_files, :transcription_id, algorithm: :concurrently
  end
end
