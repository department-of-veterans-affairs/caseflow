# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161103200652) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", force: :cascade do |t|
    t.string "vacols_id", null: false
    t.string "vbms_id"
  end

  add_index "appeals", ["vacols_id"], name: "index_appeals_on_vacols_id", unique: true, using: :btree

  create_table "certifications", force: :cascade do |t|
    t.string   "vacols_id"
    t.boolean  "already_certified"
    t.boolean  "vacols_data_missing"
    t.datetime "nod_matching_at"
    t.datetime "soc_matching_at"
    t.datetime "form9_matching_at"
    t.boolean  "ssocs_required"
    t.datetime "ssocs_matching_at"
    t.datetime "form8_started_at"
    t.datetime "completed_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "form8s", force: :cascade do |t|
    t.string   "vacols_id"
    t.string   "_initial_appellant_name"
    t.string   "appellant_name"
    t.string   "_initial_appellant_relationship"
    t.string   "appellant_relationship"
    t.string   "file_number"
    t.string   "_initial_veteran_name"
    t.string   "veteran_name"
    t.string   "_initial_insurance_loan_number"
    t.string   "insurance_loan_number"
    t.text     "_initial_service_connection_for"
    t.text     "service_connection_for"
    t.datetime "_initial_service_connection_notification_date"
    t.datetime "service_connection_notification_date"
    t.text     "_initial_increased_rating_for"
    t.text     "increased_rating_for"
    t.datetime "_initial_increased_rating_notification_date"
    t.datetime "increased_rating_notification_date"
    t.text     "_initial_other_for"
    t.text     "other_for"
    t.datetime "_initial_other_notification_date"
    t.datetime "other_notification_date"
    t.string   "_initial_representative_name"
    t.string   "representative_name"
    t.string   "_initial_representative_type"
    t.integer  "representative_type"
    t.string   "_initial_representative_type_specify_other"
    t.string   "representative_type_specify_other"
    t.string   "_initial_power_of_attorney"
    t.string   "power_of_attorney"
    t.string   "_initial_power_of_attorney_file"
    t.string   "power_of_attorney_file"
    t.string   "_initial_agent_accredited"
    t.string   "agent_accredited"
    t.boolean  "_initial_form_646_of_record"
    t.boolean  "form_646_of_record"
    t.string   "_initial_form_646_not_of_record_explanation"
    t.string   "form_646_not_of_record_explanation"
    t.boolean  "_initial_hearing_requested"
    t.boolean  "hearing_requested"
    t.boolean  "_initial_hearing_held"
    t.boolean  "hearing_held"
    t.boolean  "_initial_hearing_transcript_on_file"
    t.boolean  "hearing_transcript_on_file"
    t.string   "_initial_hearing_requested_explanation"
    t.string   "hearing_requested_explanation"
    t.boolean  "_initial_contested_claims_procedures_applicable"
    t.boolean  "contested_claims_procedures_applicable"
    t.boolean  "_initial_contested_claims_requirements_followed"
    t.boolean  "contested_claims_requirements_followed"
    t.datetime "_initial_soc_date"
    t.datetime "soc_date"
    t.string   "_initial_ssoc_required"
    t.integer  "ssoc_required"
    t.text     "_initial_record_other_explanation",               array: true
    t.text     "record_other_explanation",                        array: true
    t.text     "_initial_remarks"
    t.text     "remarks"
    t.string   "certifying_office"
    t.string   "certifying_username"
    t.string   "_initial_certifying_official_name"
    t.string   "certifying_official_name"
    t.string   "_initial_certifying_official_title"
    t.string   "certifying_official_title"
    t.datetime "certification_date"
    t.integer  "record_cf_or_xcf"
    t.integer  "record_inactive_cf"
    t.integer  "record_dental_f"
    t.integer  "record_r_and_e_f"
    t.integer  "record_training_sub_f"
    t.integer  "record_loan_guar_f"
    t.integer  "record_outpatient_f"
    t.integer  "record_hospital_cor"
    t.integer  "record_clinical_rec"
    t.integer  "record_x_rays"
    t.integer  "record_slides"
    t.integer  "record_tissue_blocks"
    t.integer  "record_dep_ed_f"
    t.integer  "record_insurance_f"
    t.integer  "record_other"
  end

  create_table "users", force: :cascade do |t|
    t.string "station_id", null: false
    t.string "css_id",     null: false
  end

  add_index "users", ["station_id", "css_id"], name: "index_users_on_station_id_and_css_id", unique: true, using: :btree

end
