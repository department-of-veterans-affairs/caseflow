class CreateEtlAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :appeals, comment: "Denormalized BVA NODs" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      # Appeals attributes
      t.bigint "appeal_id", null: false, comment: "ID of the Appeal"
      t.string "docket_number", null: false, limit: 50, comment: "Docket number"
      t.string "docket_type", null: false, limit: 50, comment: "Docket type"
      t.string "veteran_file_number", null: false, limit: 20, comment: "Veteran file number"
      t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
      t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
      t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
      t.string "status", null: false, limit: 32, comment: "Calculated BVA status based on Tasks"
      t.boolean "active_appeal", null: false, comment: "Calculated based on BVA status"
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
      t.index ["appeal_id"]
      t.index ["status"]
      t.index ["active_appeal"]

      # denormalized attributes (one Veteran and one Claimant per Appeal)
      t.bigint "veteran_id", null: false, comment: "veterans.id"
      t.string "veteran_first_name", comment: "veterans.first_name"
      t.string "veteran_middle_name", comment: "veterans.middle_name"
      t.string "veteran_last_name", comment: "veterans.last_name"
      t.string "veteran_name_suffix", comment: "veterans.name_suffix"
      t.string "veteran_participant_id", limit: 20, comment: "veterans.participant_id"
      t.date "veteran_dob", comment: "people.date_of_birth"

      t.index ["veteran_participant_id"]
      t.index ["veteran_id"]

      t.bigint "claimant_id", comment: "claimants.id"
      t.string "claimant_payee_code", limit: 20, comment: "claimants.payee_code"
      t.string "claimant_participant_id", limit: 20, comment: "claimants.participant_id"
      t.bigint "claimant_person_id", comment: "people.id"
      t.string "claimant_first_name", comment: "people.first_name"
      t.string "claimant_middle_name", comment: "people.middle_name"
      t.string "claimant_last_name", comment: "people.last_name"
      t.string "claimant_name_suffix", comment: "people.name_suffix"

      t.index ["claimant_id"]
      t.index ["claimant_participant_id"]
      t.index ["claimant_person_id"]

      # AOD is 1:1 with claimant via people, most recent preferred.
      t.boolean "aod_granted", null: false, default: false, comment: "advance_on_docket_motions.granted"
      t.string "aod_reason", limit: 50, comment: "advance_on_docket_motions.reason"
      t.bigint "aod_user_id", comment: "advance_on_docket_motions.user_id"

      t.index ["aod_user_id"]
      t.index ["aod_granted"]
    end
  end
end
