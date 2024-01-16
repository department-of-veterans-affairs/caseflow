class AddTranscriptionTransactionsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :transcription_transactions do |t|
      t.belongs_to :transcription, null: false, comment: "Transcription that is associated with this record"
      t.bigint :appeal_id, comment: "The ID of the appeal associated with this record"
      t.string :appeal_type, comment: "The type of appeal associated with this record"
      t.string :file_name, null: false
      t.string :docket_number, null: false
      t.timestamp :date_receipt_webex, null: false
      t.string :file_status, null: false
      t.string :aws_link, null: true
      t.timestamp :date_uploaded_aws, null: true
    end
  end
end
