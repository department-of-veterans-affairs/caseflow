class CreateEtlAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :appeals, comment: "Denormalized BVA NODs" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"

      t.integer "appeal_id", null: false, comment: "ID of the Appeal"
      t.string "docket_number", null: false, limit: 50, comment: "Docket number"
      t.string "docket_type", null: false, limit: 50, comment: "Docket type"
      t.string "veteran_file_number", null: false, limit: 20, comment: "Veteran file number"
      t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
      t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
      t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
      t.string "status", null: false, limit: 32, comment: "Calculated BVA status based on Tasks"
      t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
      t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
      t.string "poa_participant_id", limit: 20, comment: "Used to identify the power of attorney (POA)"
      t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
      t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
      t.string "closest_regional_office", limit: 20, comment: "The code for the regional office closest to the Veteran on the appeal."

      t.index ["veteran_is_not_claimant"]
      t.index ["uuid"]
      t.index ["veteran_file_number"]
      t.index ["docket_type"]
      t.index ["receipt_date"]
      t.index ["poa_participant_id"]
    end
  end
end
