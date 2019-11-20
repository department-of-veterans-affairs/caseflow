# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191119204827) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", force: :cascade, comment: "Denormalized BVA NODs" do |t|
    t.bigint "appeal_id", null: false, comment: "ID of the Appeal"
    t.date "claimant_dob", comment: "people.date_of_birth"
    t.string "claimant_first_name", comment: "people.first_name"
    t.bigint "claimant_id", comment: "claimants.id"
    t.string "claimant_last_name", comment: "people.last_name"
    t.string "claimant_middle_name", comment: "people.middle_name"
    t.string "claimant_name_suffix", comment: "people.name_suffix"
    t.string "claimant_participant_id", limit: 20, comment: "claimants.participant_id"
    t.string "claimant_payee_code", limit: 20, comment: "claimants.payee_code"
    t.bigint "claimant_person_id", comment: "people.id"
    t.string "closest_regional_office", limit: 20, comment: "The code for the regional office closest to the Veteran on the appeal."
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.string "docket_number", limit: 50, null: false, comment: "Docket number"
    t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
    t.string "docket_type", limit: 50, null: false, comment: "Docket type"
    t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
    t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
    t.string "poa_participant_id", limit: 20, comment: "Used to identify the power of attorney (POA)"
    t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
    t.string "status", limit: 32, null: false, comment: "Calculated BVA status based on Tasks"
    t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
    t.string "veteran_file_number", limit: 20, null: false, comment: "Veteran file number"
    t.string "veteran_first_name", comment: "veterans.first_name"
    t.bigint "veteran_id", null: false, comment: "veterans.id"
    t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
    t.string "veteran_last_name", comment: "veterans.last_name"
    t.string "veteran_middle_name", comment: "veterans.middle_name"
    t.string "veteran_name_suffix", comment: "veterans.name_suffix"
    t.string "veteran_participant_id", limit: 20, comment: "veterans.participant_id"
    t.index ["appeal_id"], name: "index_appeals_on_appeal_id"
    t.index ["claimant_id"], name: "index_appeals_on_claimant_id"
    t.index ["claimant_participant_id"], name: "index_appeals_on_claimant_participant_id"
    t.index ["claimant_person_id"], name: "index_appeals_on_claimant_person_id"
    t.index ["docket_type"], name: "index_appeals_on_docket_type"
    t.index ["poa_participant_id"], name: "index_appeals_on_poa_participant_id"
    t.index ["receipt_date"], name: "index_appeals_on_receipt_date"
    t.index ["uuid"], name: "index_appeals_on_uuid"
    t.index ["veteran_file_number"], name: "index_appeals_on_veteran_file_number"
    t.index ["veteran_id"], name: "index_appeals_on_veteran_id"
    t.index ["veteran_is_not_claimant"], name: "index_appeals_on_veteran_is_not_claimant"
    t.index ["veteran_participant_id"], name: "index_appeals_on_veteran_participant_id"
  end

  create_table "users", force: :cascade, comment: "Combined Caseflow/VACOLS user lookups" do |t|
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.string "css_id", limit: 20, null: false, comment: "CSEM (Active Directory) username"
    t.string "email", limit: 255, comment: "CSEM email"
    t.string "full_name", limit: 255, comment: "CSEM full name"
    t.datetime "last_login_at"
    t.string "roles", array: true
    t.string "sactive", limit: 1, null: false
    t.string "sattyid", limit: 20
    t.string "selected_regional_office", limit: 255, comment: "CSEM regional office"
    t.string "slogid", limit: 20, null: false
    t.string "stafkey", limit: 20, null: false
    t.string "station_id", limit: 20, null: false, comment: "CSEM station"
    t.string "status", limit: 20, default: "active", comment: "Whether or not the user is an active user of caseflow"
    t.datetime "status_updated_at", comment: "When the user's status was last updated"
    t.string "svlj", limit: 1
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.integer "user_id", null: false, comment: "ID of the User"
    t.index "upper((css_id)::text)", name: "index_users_on_upper_css_id_text", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

end
