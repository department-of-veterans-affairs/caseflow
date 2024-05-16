class AddTranscriptionContractorIdToTranscriptions < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_column :transcriptions, :transcription_contractor_id, :bigint
    add_index :transcriptions, :transcription_contractor_id, algorithm: :concurrently
  end
end
