class AddIndexesToTranscriptions < Caseflow::Migration
  def change
    add_safe_index :transcriptions, [:transcription_contractor_id], name: "index_transcriptions_on_transcription_contractor_id"
    add_safe_index :transcriptions, [:deleted_at], name: "index_transcriptions_on_deleted_at"
  end
end
