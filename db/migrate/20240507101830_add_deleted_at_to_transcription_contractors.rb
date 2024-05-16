class AddDeletedAtToTranscriptionContractors < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_column :transcription_contractors, :deleted_at, :datetime
    add_index :transcription_contractors, :deleted_at, algorithm: :concurrently
  end
end
