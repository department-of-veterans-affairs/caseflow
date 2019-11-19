class CreateEtlAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :appeals do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.integer "appeal_id", null: false, comment: "ID of the Appeal"
      t.string "docket_number", null: false, limit: 50, comment: "Docket number"
      t.string "docket_type", null: false, limit: 50, comment: "Docket type"
      t.string "veteran_file_number", null: false, limit: 20, comment: "Veteran file number"
      t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
      t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
      t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
      t.string "status", null: false, limit: 32, comment: "Calculated BVA status based on Tasks"
    end
  end
end
