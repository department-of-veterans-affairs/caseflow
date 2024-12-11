class UpdateTranscriptionPackageHearings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_foreign_key :transcription_package_hearings, :hearings
    remove_foreign_key :transcription_package_hearings, :transcription_packages
    remove_foreign_key :transcription_package_legacy_hearings, :legacy_hearings
    remove_foreign_key :transcription_package_legacy_hearings, :transcription_packages
    drop_table :transcription_package_legacy_hearings
    add_column :transcription_package_hearings, :hearing_type, :string,
    add_index :transcription_package_hearings, [:hearing_type, :hearing_id], algorithm: :concurrently, name: "index_transcription_package_hearings"
  end
end
