class AddIndexToTranscriptionPackagesContractorId < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_index :transcription_packages, :contractor_id, name: "index_transcription_packages_on_contractor_id", algorithm: :concurrently
  end
end
