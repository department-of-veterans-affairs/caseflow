class UpdateTranscriptionPackagesColumns < Caseflow::Migration

  def change
    add_column :transcription_packages, :date_upload_box, :datetime, comment: "Date of successful delivery to box.com contractor endpoint"
    add_column :transcription_packages, :date_upload_aws, :datetime, comment: "Date of successful upload of master transcription zip file to AWS"

    change_column_null :transcription_packages, :returned_at, true
    change_column_null :transcription_packages, :updated_at, true
    add_reference :transcription_packages, :contractor, index: false, foreign_key: { to_table: :transcription_contractors }, comment: "FK to transcription_contractors table"
  end
end
