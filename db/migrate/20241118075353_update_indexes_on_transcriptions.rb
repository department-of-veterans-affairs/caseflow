class UpdateIndexesOnTranscriptions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    unless index_exists?(:transcriptions, :transcription_contractor_id, name: "index_transcriptions_on_transcription_contractor_id")
      add_index :transcriptions, :transcription_contractor_id, name: "index_transcriptions_on_transcription_contractor_id",algorithm: :concurrently
    end

    unless index_exists?(:transcriptions, :deleted_at, name: "index_transcriptions_on_deleted_at")
      add_index :transcriptions, :deleted_at, name: "index_transcriptions_on_deleted_at",algorithm: :concurrently
    end
  end
end
