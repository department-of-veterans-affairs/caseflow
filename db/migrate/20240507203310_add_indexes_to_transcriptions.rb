class AddIndexesToTranscriptions < ActiveRecord::Migration[6.1]
  def change
    add_index :transcriptions, :transcription_contractor_id, algorithm: :concurrently, name: "index_transcriptions_on_transcription_contractor_id"
    add_index :transcriptions, :deleted_at, algorithm: :concurrently, name: "index_transcriptions_on_deleted_at"
  end
end
