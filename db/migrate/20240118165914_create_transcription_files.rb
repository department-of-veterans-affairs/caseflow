class CreateTranscriptionFiles < Caseflow::Migration
  def change
    create_table :transcription_files do |t|
      t.string :file_name, null: false, comment: "File name, with extension, of the transcription file migrated by caseflow"
      t.string :file_type, null: false, comment: "One of mp4, vtt, mp3, rtf, pdf, xls"
      t.bigint :hearing_id, null: false, comment: "ID of the hearing associated with this record"
      t.string :hearing_type, null: false, comment: "Type of hearing associated with this record"
      t.string :docket_number, null: false, comment: "Docket number of associated hearing"
      t.string :file_status, comment: "Status of the file, could be one of nil, 'Successful retrieval (Webex), Failed retrieval (Webex), Sucessful conversion, Failed conversion, Successful upload (AWS), Failed upload (AWS)'"
      t.string :aws_link, comment: "Link to be used by HMB to download original or transformed file"

      t.datetime :date_receipt_webex, comment: "Timestamp when file was added to webex"
      t.datetime :date_converted, comment: "Timestamp when file was converted from vtt to rtf"
      t.datetime :date_upload_box, comment: "Timestamp when file was added to box"
      t.datetime :date_upload_aws, comment: "Timestamp when file was loaded to AWS"

      t.bigint :created_by_id, comment: "The user who created the transcription record"
      t.bigint :updated_by_id, comment: "The user who most recently updated the transcription file"
      t.timestamps
    end

    add_index :transcription_files,
              [:file_name, :docket_number, :hearing_id, :hearing_type],
              unique: true,
              name: "idx_transcription_files_on_file_name_and_docket_num_and_hearing"
    add_index :transcription_files,
              [:hearing_id, :hearing_type, :docket_number],
              name: "index_transcription_files_on_docket_number_and_hearing"
    add_index :transcription_files, [:hearing_id, :hearing_type]
    add_index :transcription_files, [:docket_number]
    add_index :transcription_files, [:file_type]
    add_index :transcription_files, [:aws_link]
  end
end
