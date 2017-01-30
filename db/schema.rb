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

ActiveRecord::Schema.define(version: 20170127155914) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", force: :cascade do |t|
    t.string  "vacols_id",                                              null: false
    t.string  "vbms_id"
    t.boolean "rice_compliance",                        default: false
    t.boolean "private_attorney",                       default: false
    t.boolean "waiver_of_overpayment",                  default: false
    t.boolean "pensions",                               default: false
    t.boolean "vamc",                                   default: false
    t.boolean "incarcerated_veterans",                  default: false
    t.boolean "dic_death_or_accrued_benefits",          default: false
    t.boolean "education_or_vocational_rehab",          default: false
    t.boolean "foreign_claims",                         default: false
    t.boolean "manlincon_compliance",                   default: false
    t.boolean "hearings_travel_board_video_conference", default: false
    t.boolean "home_loan_guaranty",                     default: false
    t.boolean "insurance",                              default: false
    t.boolean "national_cemetery_administration",       default: false
    t.boolean "spina_bifida",                           default: false
    t.boolean "radiation",                              default: false
    t.boolean "nonrating_issues",                       default: false
    t.boolean "proposed_incompetency",                  default: false
    t.boolean "manila_remand",                          default: false
    t.boolean "contaminated_water_at_camp_lejeune",     default: false
    t.boolean "mustard_gas",                            default: false
    t.boolean "dependencies",                           default: false
  end

  add_index "appeals", ["vacols_id"], name: "index_appeals_on_vacols_id", unique: true, using: :btree

  create_table "certification_cancellations", force: :cascade do |t|
    t.integer "certification_id"
    t.string  "cancellation_reason"
    t.string  "other_reason"
    t.string  "email"
  end

  add_index "certification_cancellations", ["certification_id"], name: "index_certification_cancellations_on_certification_id", unique: true, using: :btree

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
    t.integer  "user_id"
  end

  add_index "certifications", ["user_id"], name: "index_certifications_on_user_id", using: :btree

  create_table "form8s", force: :cascade do |t|
    t.integer  "certification_id"
    t.string   "vacols_id"
    t.string   "appellant_name"
    t.string   "appellant_relationship"
    t.string   "file_number"
    t.string   "veteran_name"
    t.string   "insurance_loan_number"
    t.text     "service_connection_for"
    t.date     "service_connection_notification_date"
    t.text     "increased_rating_for"
    t.date     "increased_rating_notification_date"
    t.text     "other_for"
    t.date     "other_notification_date"
    t.string   "representative_name"
    t.string   "representative_type"
    t.string   "representative_type_specify_other"
    t.string   "power_of_attorney"
    t.string   "power_of_attorney_file"
    t.string   "agent_accredited"
    t.string   "form_646_of_record"
    t.string   "form_646_not_of_record_explanation"
    t.string   "hearing_requested"
    t.string   "hearing_held"
    t.string   "hearing_transcript_on_file"
    t.string   "hearing_requested_explanation"
    t.string   "contested_claims_procedures_applicable"
    t.string   "contested_claims_requirements_followed"
    t.date     "soc_date"
    t.string   "ssoc_required"
    t.text     "record_other_explanation"
    t.text     "remarks"
    t.string   "certifying_office"
    t.string   "certifying_username"
    t.string   "certifying_official_name"
    t.string   "certifying_official_title"
    t.date     "certification_date"
    t.string   "record_cf_or_xcf"
    t.string   "record_inactive_cf"
    t.string   "record_dental_f"
    t.string   "record_r_and_e_f"
    t.string   "record_training_sub_f"
    t.string   "record_loan_guar_f"
    t.string   "record_outpatient_f"
    t.string   "record_hospital_cor"
    t.string   "record_clinical_rec"
    t.string   "record_x_rays"
    t.string   "record_slides"
    t.string   "record_tissue_blocks"
    t.string   "record_dep_ed_f"
    t.string   "record_insurance_f"
    t.string   "record_other"
    t.string   "_initial_appellant_name"
    t.string   "_initial_appellant_relationship"
    t.string   "_initial_veteran_name"
    t.string   "_initial_insurance_loan_number"
    t.date     "_initial_service_connection_notification_date"
    t.date     "_initial_increased_rating_notification_date"
    t.date     "_initial_other_notification_date"
    t.date     "_initial_soc_date"
    t.string   "_initial_representative_name"
    t.string   "_initial_representative_type"
    t.string   "_initial_hearing_requested"
    t.string   "_initial_ssoc_required"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "certifying_official_title_specify_other"
  end

  add_index "form8s", ["certification_id"], name: "index_form8s_on_certification_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.integer  "appeal_id",             null: false
    t.string   "type",                  null: false
    t.integer  "user_id"
    t.datetime "assigned_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "completion_status"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "lock_version"
    t.string   "comment"
    t.string   "outgoing_reference_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "station_id", null: false
    t.string "css_id",     null: false
    t.string "full_name"
    t.string "email"
  end

  add_index "users", ["station_id", "css_id"], name: "index_users_on_station_id_and_css_id", unique: true, using: :btree

  add_foreign_key "certifications", "users"
end
