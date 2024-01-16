class CreateTranscriptionTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transcription_transactions do |t|
      t.string :file_name, null: false, comment: "The file name, with extension, of the transcription file migrated by Caseflow"
      t.references :appeal, null: false, foreign_key: true, index: { unique: true }, comment: "Appeal ID"
      t.string :docket_number, null: false, index: { unique: true }, comment: "Docket ID"
      t.datetime :date_receipt_webex, null: false, comment: "Timestamp when file was added to webex"
      t.datetime :date_vtt_converted, null: false, comment: "Timestamp when file was converted from vtt"
      t.datetime :date_mp4_converted, null: false, comment: "Timestamp when file was converted from mp4"
      t.datetime :date_upload_box, null: false, comment: "Timestamp when file was added to box"
      t.datetime :date_upload_aws, null: false, comment: "Timestamp when file was loaded to AWS"
      t.string :file_status, null: false, index: { unique: true }, comment: "The status of the file, could be one of nil, 'Found in BOX', 'Error in upload to BOX', 'AWS Uploaded', 'Error in upload to AWS', or 'File Upload out of Sequence'"
      t.string :aws_link_mp4, null: false, index: { unique: true }, comment: "Link to be used by HMB to download original audio file from AWS S3"
      t.string :aws_link_vtt, null: false, index: { unique: true }, comment: "Link to be used by HMB to download original transcript file from AWS S3"
      t.string :aws_link_mp3, null: false, index: { unique: true }, comment: "Link to be used by HMB to download transformed audio file from AWS S3"
      t.string :aws_link_rtf, null: false, index: { unique: true }, comment: "Link to be used by HMB to download transformed transcript file from AWS S3"
      t.string :aws_link_pdf, null: false, comment: "Link to be used by HMB to download pdf transcript file from AWS S3"
      t.bigint :created_by_id, null: false, comment: "The user who created the transcription record"
      t.bigint :updated_by_id, null: false, comment: "The user who most recently updated the transcription file"
      t.timestamps
    end
  end
end
