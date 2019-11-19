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

ActiveRecord::Schema.define(version: 20191111164808) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", force: :cascade, comment: "Denormalized BVA NODs" do |t|
    t.integer "appeal_id", null: false, comment: "ID of the Appeal"
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
    t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
    t.index ["docket_type"], name: "index_appeals_on_docket_type"
    t.index ["poa_participant_id"], name: "index_appeals_on_poa_participant_id"
    t.index ["receipt_date"], name: "index_appeals_on_receipt_date"
    t.index ["uuid"], name: "index_appeals_on_uuid"
    t.index ["veteran_file_number"], name: "index_appeals_on_veteran_file_number"
    t.index ["veteran_is_not_claimant"], name: "index_appeals_on_veteran_is_not_claimant"
  end

end
