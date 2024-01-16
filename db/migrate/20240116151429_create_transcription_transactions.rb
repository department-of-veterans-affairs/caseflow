class CreateTranscriptionTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transcription_transactions do |t|
      t.string :file_name, null: false, comment: "File name, with extension, of the transcription file migrated by caseflow"
      t.bigint :appeal_id, null: false, comment: "ID of the appeal associated with this record"
      t.string :appeal_type, null: false, comment: "Type of appeal associated with this record"
      t.string :docket_number, null: false, comment: "Docket number of associated appeal"
      t.string :file_status, null: false, comment: "Status of the file, could be one of nil, 'Found in BOX', 'Error in upload to BOX', 'AWS Uploaded', 'Error in upload to AWS', or 'File Upload out of Sequence'"

      t.datetime :date_receipt_webex, null: false, comment: "Timestamp when file was added to webex"
      t.datetime :date_vtt_converted, null: false, comment: "Timestamp when file was converted from vtt"
      t.datetime :date_mp4_converted, null: false, comment: "Timestamp when file was converted from mp4"
      t.datetime :date_upload_box, null: false, comment: "Timestamp when file was added to box"
      t.datetime :date_upload_aws, null: false, comment: "Timestamp when file was loaded to AWS"

      t.string :aws_link_mp4, null: false, comment: "Link to be used by HMB to download original audio file from AWS S3"
      t.string :aws_link_vtt, null: false, comment: "Link to be used by HMB to download original transcript file from AWS S3"
      t.string :aws_link_mp3, null: false, comment: "Link to be used by HMB to download transformed audio file from AWS S3"
      t.string :aws_link_rtf, null: false, comment: "Link to be used by HMB to download transformed transcript file from AWS S3"
      t.string :aws_link_pdf, null: false, comment: "Link to be used by HMB to download pdf transcript file from AWS S3"
      t.string :aws_link_xls, null: false, comment: "Link to be used by HMB to download a transcript error file report from AWS S3"

      t.bigint :created_by_id, null: false, comment: "The user who created the transcription record"
      t.bigint :updated_by_id, null: false, comment: "The user who most recently updated the transcription file"
      t.timestamps
    end

    add_index :transcription_transactions,
              [:appeal_id, :appeal_type, :docket_number, :file_status, :aws_link_mp4, :aws_link_mp3, :aws_link_vtt, :aws_link_rtf],
              unique: true,
              name: "idx_transcript_transactions_on_appeal_and_file_status_and_links"
    add_index :transcription_transactions,
              [:appeal_id, :appeal_type, :docket_number],
              unique: true,
              name: "idx_transcription_transactions_on_appeal_and_docket_number"
    add_index :transcription_transactions, [:appeal_id, :appeal_type], unique: true
    add_index :transcription_transactions, [:docket_number], unique: true
    add_index :transcription_transactions, [:file_status], unique: true
    add_index :transcription_transactions, [:aws_link_mp4], unique: true
    add_index :transcription_transactions, [:aws_link_mp3], unique: true
    add_index :transcription_transactions, [:aws_link_vtt], unique: true
    add_index :transcription_transactions, [:aws_link_rtf], unique: true
  end
end
