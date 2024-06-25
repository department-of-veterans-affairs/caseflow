class CreateTranscriptionPackageLegacyHearings < ActiveRecord::Migration[6.0]
  def change
    create_table :transcription_package_legacy_hearings do |t|
      t.references :transcription_package, index: false, foreign_key: true
      t.references :legacy_hearing, index: false, foreign_key: true
    end
  end
end
