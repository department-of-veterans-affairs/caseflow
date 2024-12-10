class CreateTranscriptionPackageHearings < ActiveRecord::Migration[6.0]
  def change
    create_table :transcription_package_hearings do |t|
      t.references :transcription_package, index: false, foreign_key: true
      t.references :hearing, index: false, foreign_key: true
    end
  end
end
