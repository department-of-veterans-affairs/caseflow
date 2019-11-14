class CreateEtlAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :appeals do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.integer "appeal_id", null: false, comment: "ID of the Appeal"
      t.string "docket_number", null: false, comment: "Docket number"
      t.string "docket_type", null: false, comment: "Docket type"
      t.string "veteran_file_number", null: false, comment: "Veteran file number"
      t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
      t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
      t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
    end
  end
end
