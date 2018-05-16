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

ActiveRecord::Schema.define(version: 20180516213251) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.string "comment", null: false
    t.integer "page"
    t.integer "x"
    t.integer "y"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "relevant_date"
    t.index ["document_id"], name: "index_annotations_on_document_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "consumer_name", null: false
    t.string "key_digest", null: false
    t.index ["consumer_name"], name: "index_api_keys_on_consumer_name", unique: true
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
  end

  create_table "api_views", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "vbms_id"
    t.integer "api_key_id"
  end

  create_table "appeal_series", id: :serial, force: :cascade do |t|
    t.boolean "incomplete", default: false
    t.integer "merged_appeal_count"
  end

  create_table "appeal_views", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "appeal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_viewed_at"
    t.index ["appeal_id", "user_id"], name: "index_appeal_views_on_appeal_id_and_user_id", unique: true
  end

  create_table "appeals", id: :serial, force: :cascade do |t|
    t.string "vacols_id", null: false
    t.string "vbms_id"
    t.boolean "rice_compliance", default: false
    t.boolean "private_attorney_or_agent", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.boolean "pension_united_states", default: false
    t.boolean "vamc", default: false
    t.boolean "incarcerated_veterans", default: false
    t.boolean "dic_death_or_accrued_benefits_united_states", default: false
    t.boolean "vocational_rehab", default: false
    t.boolean "foreign_claim_compensation_claims_dual_claims_appeals", default: false
    t.boolean "manlincon_compliance", default: false
    t.boolean "hearing_including_travel_board_video_conference", default: false
    t.boolean "home_loan_guaranty", default: false
    t.boolean "insurance", default: false
    t.boolean "national_cemetery_administration", default: false
    t.boolean "spina_bifida", default: false
    t.boolean "radiation", default: false
    t.boolean "nonrating_issue", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.boolean "mustard_gas", default: false
    t.boolean "education_gi_bill_dependents_educational_assistance_scholars", default: false
    t.boolean "foreign_pension_dic_all_other_foreign_countries", default: false
    t.boolean "foreign_pension_dic_mexico_central_and_south_america_caribb", default: false
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.string "dispatched_to_station"
    t.integer "appeal_series_id"
    t.boolean "issues_pulled"
    t.index ["appeal_series_id"], name: "index_appeals_on_appeal_series_id"
    t.index ["vacols_id"], name: "index_appeals_on_vacols_id", unique: true
  end

  create_table "attorney_case_reviews", id: :serial, force: :cascade do |t|
    t.string "document_id"
    t.integer "reviewing_judge_id"
    t.integer "attorney_id"
    t.string "work_product"
    t.boolean "overtime", default: false
    t.string "type"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "task_id"
  end

  create_table "certification_cancellations", id: :serial, force: :cascade do |t|
    t.integer "certification_id"
    t.string "cancellation_reason"
    t.string "other_reason"
    t.string "email"
    t.index ["certification_id"], name: "index_certification_cancellations_on_certification_id", unique: true
  end

  create_table "certifications", id: :serial, force: :cascade do |t|
    t.string "vacols_id"
    t.boolean "already_certified"
    t.boolean "vacols_data_missing"
    t.datetime "nod_matching_at"
    t.datetime "soc_matching_at"
    t.datetime "form9_matching_at"
    t.boolean "ssocs_required"
    t.datetime "ssocs_matching_at"
    t.datetime "form8_started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "bgs_representative_type"
    t.string "bgs_representative_name"
    t.string "vacols_representative_type"
    t.string "vacols_representative_name"
    t.string "representative_type"
    t.string "representative_name"
    t.boolean "hearing_change_doc_found_in_vbms"
    t.string "form9_type"
    t.string "vacols_hearing_preference"
    t.string "hearing_preference"
    t.string "certifying_office"
    t.string "certifying_username"
    t.string "certifying_official_name"
    t.string "certifying_official_title"
    t.string "certification_date"
    t.boolean "poa_matches"
    t.boolean "poa_correct_in_vacols"
    t.boolean "poa_correct_in_bgs"
    t.string "bgs_rep_address_line_1"
    t.string "bgs_rep_address_line_2"
    t.string "bgs_rep_address_line_3"
    t.string "bgs_rep_city"
    t.string "bgs_rep_country"
    t.string "bgs_rep_state"
    t.string "bgs_rep_zip"
    t.boolean "v2"
    t.boolean "loading_data"
    t.boolean "loading_data_failed"
    t.index ["user_id"], name: "index_certifications_on_user_id"
  end

  create_table "claim_establishments", id: :serial, force: :cascade do |t|
    t.integer "task_id"
    t.integer "decision_type"
    t.datetime "outcoding_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email_ro_id"
    t.string "email_recipient"
    t.string "ep_code"
  end

  create_table "claims_folder_searches", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "appeal_id"
    t.string "query"
    t.datetime "created_at"
  end

  create_table "dispatch_tasks", id: :serial, force: :cascade do |t|
    t.integer "appeal_id", null: false
    t.string "type", null: false
    t.integer "user_id"
    t.datetime "assigned_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "completion_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version"
    t.string "comment"
    t.string "outgoing_reference_id"
    t.string "aasm_state"
    t.datetime "prepared_at"
  end

  create_table "docket_snapshots", id: :serial, force: :cascade do |t|
    t.integer "docket_count"
    t.date "latest_docket_month"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "docket_tracers", id: :serial, force: :cascade do |t|
    t.integer "docket_snapshot_id"
    t.date "month"
    t.integer "ahead_count"
    t.integer "ahead_and_ready_count"
    t.index ["docket_snapshot_id", "month"], name: "index_docket_tracers_on_docket_snapshot_id_and_month", unique: true
  end

  create_table "document_views", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "user_id", null: false
    t.datetime "first_viewed_at"
    t.index ["document_id", "user_id"], name: "index_document_views_on_document_id_and_user_id", unique: true
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.string "vbms_document_id", null: false
    t.boolean "category_procedural"
    t.boolean "category_medical"
    t.boolean "category_other"
    t.date "received_at"
    t.string "type"
    t.string "file_number"
    t.string "description"
    t.string "series_id"
    t.integer "previous_document_version_id"
    t.index ["file_number"], name: "index_documents_on_file_number"
    t.index ["series_id"], name: "index_documents_on_series_id"
    t.index ["vbms_document_id"], name: "index_documents_on_vbms_document_id", unique: true
  end

  create_table "documents_tags", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "tag_id", null: false
    t.index ["document_id", "tag_id"], name: "index_documents_tags_on_document_id_and_tag_id", unique: true
  end

  create_table "form8s", id: :serial, force: :cascade do |t|
    t.integer "certification_id"
    t.string "vacols_id"
    t.string "appellant_name"
    t.string "appellant_relationship"
    t.string "file_number"
    t.string "veteran_name"
    t.string "insurance_loan_number"
    t.text "service_connection_for"
    t.date "service_connection_notification_date"
    t.text "increased_rating_for"
    t.date "increased_rating_notification_date"
    t.text "other_for"
    t.date "other_notification_date"
    t.string "representative_name"
    t.string "representative_type"
    t.string "representative_type_specify_other"
    t.string "power_of_attorney"
    t.string "power_of_attorney_file"
    t.string "agent_accredited"
    t.string "form_646_of_record"
    t.string "form_646_not_of_record_explanation"
    t.string "hearing_requested"
    t.string "hearing_held"
    t.string "hearing_transcript_on_file"
    t.string "hearing_requested_explanation"
    t.string "contested_claims_procedures_applicable"
    t.string "contested_claims_requirements_followed"
    t.date "soc_date"
    t.string "ssoc_required"
    t.text "record_other_explanation"
    t.text "remarks"
    t.string "certifying_office"
    t.string "certifying_username"
    t.string "certifying_official_name"
    t.string "certifying_official_title"
    t.date "certification_date"
    t.string "record_cf_or_xcf"
    t.string "record_inactive_cf"
    t.string "record_dental_f"
    t.string "record_r_and_e_f"
    t.string "record_training_sub_f"
    t.string "record_loan_guar_f"
    t.string "record_outpatient_f"
    t.string "record_hospital_cor"
    t.string "record_clinical_rec"
    t.string "record_x_rays"
    t.string "record_slides"
    t.string "record_tissue_blocks"
    t.string "record_dep_ed_f"
    t.string "record_insurance_f"
    t.string "record_other"
    t.string "_initial_appellant_name"
    t.string "_initial_appellant_relationship"
    t.string "_initial_veteran_name"
    t.string "_initial_insurance_loan_number"
    t.date "_initial_service_connection_notification_date"
    t.date "_initial_increased_rating_notification_date"
    t.date "_initial_other_notification_date"
    t.date "_initial_soc_date"
    t.string "_initial_representative_name"
    t.string "_initial_representative_type"
    t.string "_initial_hearing_requested"
    t.string "_initial_ssoc_required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "certifying_official_title_specify_other"
    t.string "hearing_preference"
    t.date "nod_date"
    t.date "form9_date"
    t.date "ssoc_date_1"
    t.date "ssoc_date_2"
    t.date "ssoc_date_3"
    t.index ["certification_id"], name: "index_form8s_on_certification_id"
  end

  create_table "global_admin_logins", id: :serial, force: :cascade do |t|
    t.string "admin_css_id"
    t.string "target_css_id"
    t.string "target_station_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hearing_appeal_stream_snapshots", id: false, force: :cascade do |t|
    t.integer "hearing_id"
    t.integer "appeal_id"
    t.datetime "created_at", null: false
    t.index ["hearing_id", "appeal_id"], name: "index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids", unique: true
  end

  create_table "hearing_views", id: :serial, force: :cascade do |t|
    t.integer "hearing_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["hearing_id", "user_id"], name: "index_hearing_views_on_hearing_id_and_user_id", unique: true
  end

  create_table "hearings", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "appeal_id"
    t.string "vacols_id", null: false
    t.string "witness"
    t.string "contentions"
    t.string "evidence"
    t.string "military_service"
    t.string "comments_for_attorney"
    t.boolean "prepped"
    t.text "summary"
  end

  create_table "higher_level_reviews", force: :cascade do |t|
    t.string "veteran_file_number", null: false
    t.date "receipt_date"
    t.boolean "informal_conference"
    t.boolean "same_office"
    t.datetime "established_at"
    t.string "end_product_reference_id"
    t.string "end_product_status"
    t.datetime "end_product_status_last_synced_at"
    t.index ["veteran_file_number"], name: "index_higher_level_reviews_on_veteran_file_number"
  end

  create_table "intakes", id: :serial, force: :cascade do |t|
    t.integer "detail_id"
    t.string "detail_type"
    t.integer "user_id", null: false
    t.string "veteran_file_number"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "completion_status"
    t.string "error_code"
    t.string "type"
    t.string "cancel_reason"
    t.string "cancel_other"
    t.index ["type", "veteran_file_number"], name: "unique_index_to_avoid_duplicate_intakes", unique: true, where: "(completion_status IS NULL)"
    t.index ["type"], name: "index_intakes_on_type"
    t.index ["user_id"], name: "index_intakes_on_user_id"
    t.index ["veteran_file_number"], name: "index_intakes_on_veteran_file_number"
  end

  create_table "legacy_appeals", force: :cascade do |t|
    t.string "vacols_id", null: false
    t.string "vbms_id"
    t.boolean "rice_compliance", default: false
    t.boolean "private_attorney_or_agent", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.boolean "pension_united_states", default: false
    t.boolean "vamc", default: false
    t.boolean "incarcerated_veterans", default: false
    t.boolean "dic_death_or_accrued_benefits_united_states", default: false
    t.boolean "vocational_rehab", default: false
    t.boolean "foreign_claim_compensation_claims_dual_claims_appeals", default: false
    t.boolean "manlincon_compliance", default: false
    t.boolean "hearing_including_travel_board_video_conference", default: false
    t.boolean "home_loan_guaranty", default: false
    t.boolean "insurance", default: false
    t.boolean "national_cemetery_administration", default: false
    t.boolean "spina_bifida", default: false
    t.boolean "radiation", default: false
    t.boolean "nonrating_issue", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.boolean "mustard_gas", default: false
    t.boolean "education_gi_bill_dependents_educational_assistance_scholars", default: false
    t.boolean "foreign_pension_dic_all_other_foreign_countries", default: false
    t.boolean "foreign_pension_dic_mexico_central_and_south_america_caribb", default: false
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.string "dispatched_to_station"
    t.boolean "issues_pulled"
    t.bigint "appeal_series_id"
    t.index ["appeal_series_id"], name: "index_legacy_appeals_on_appeal_series_id"
    t.index ["vacols_id"], name: "index_legacy_appeals_on_vacols_id", unique: true
  end

  create_table "ramp_closed_appeals", id: :serial, force: :cascade do |t|
    t.string "vacols_id", null: false
    t.integer "ramp_election_id"
    t.date "nod_date"
  end

  create_table "ramp_election_rollbacks", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "ramp_election_id"
    t.string "reason"
    t.string "reopened_vacols_ids", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ramp_election_id"], name: "index_ramp_election_rollbacks_on_ramp_election_id"
    t.index ["user_id"], name: "index_ramp_election_rollbacks_on_user_id"
  end

  create_table "ramp_elections", id: :serial, force: :cascade do |t|
    t.string "veteran_file_number", null: false
    t.date "notice_date"
    t.date "receipt_date"
    t.string "option_selected"
    t.string "end_product_reference_id"
    t.datetime "established_at"
    t.string "end_product_status"
    t.datetime "end_product_status_last_synced_at"
    t.index ["veteran_file_number"], name: "index_ramp_elections_on_veteran_file_number"
  end

  create_table "ramp_issues", id: :serial, force: :cascade do |t|
    t.integer "review_id", null: false
    t.string "review_type", null: false
    t.string "contention_reference_id"
    t.string "description", null: false
    t.integer "source_issue_id"
    t.index ["review_type", "review_id"], name: "index_ramp_issues_on_review_type_and_review_id"
  end

  create_table "ramp_refilings", id: :serial, force: :cascade do |t|
    t.string "veteran_file_number", null: false
    t.integer "ramp_election_id"
    t.string "option_selected"
    t.date "receipt_date"
    t.string "end_product_reference_id"
    t.boolean "has_ineligible_issue"
    t.string "appeal_docket"
    t.datetime "established_at"
    t.index ["veteran_file_number"], name: "index_ramp_refilings_on_veteran_file_number"
  end

  create_table "reader_users", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "documents_fetched_at"
    t.index ["documents_fetched_at"], name: "index_reader_users_on_documents_fetched_at"
    t.index ["user_id"], name: "index_reader_users_on_user_id", unique: true
  end

  create_table "request_issues", force: :cascade do |t|
    t.string "review_request_type", null: false
    t.bigint "review_request_id", null: false
    t.string "rating_issue_reference_id", null: false
    t.date "rating_issue_profile_date", null: false
    t.string "contention_reference_id"
    t.string "description", null: false
    t.index ["review_request_type", "review_request_id"], name: "index_request_issues_on_review_request"
  end

  create_table "supplemental_claims", force: :cascade do |t|
    t.string "veteran_file_number", null: false
    t.date "receipt_date"
    t.datetime "established_at"
    t.string "end_product_reference_id"
    t.string "end_product_status"
    t.datetime "end_product_status_last_synced_at"
    t.index ["veteran_file_number"], name: "index_supplemental_claims_on_veteran_file_number"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["text"], name: "index_tags_on_text", unique: true
  end

  create_table "team_quotas", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.string "task_type", null: false
    t.integer "user_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "task_type"], name: "index_team_quotas_on_date_and_task_type", unique: true
  end

  create_table "temporary_appeals", force: :cascade do |t|
    t.string "veteran_file_number", null: false
    t.date "receipt_date"
    t.string "docket_type"
    t.datetime "established_at"
    t.index ["veteran_file_number"], name: "index_temporary_appeals_on_veteran_file_number"
  end

  create_table "user_quotas", id: :serial, force: :cascade do |t|
    t.integer "team_quota_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "locked_task_count"
    t.index ["team_quota_id", "user_id"], name: "index_user_quotas_on_team_quota_id_and_user_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "station_id", null: false
    t.string "css_id", null: false
    t.string "full_name"
    t.string "email"
    t.string "roles", array: true
    t.string "selected_regional_office"
    t.index ["station_id", "css_id"], name: "index_users_on_station_id_and_css_id", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "veterans", force: :cascade do |t|
    t.string "file_number", null: false
    t.string "participant_id"
    t.index ["file_number"], name: "index_veterans_on_file_number", unique: true
  end

  create_table "worksheet_issues", id: :serial, force: :cascade do |t|
    t.integer "appeal_id"
    t.string "vacols_sequence_id"
    t.boolean "reopen", default: false
    t.boolean "omo", default: false
    t.boolean "allow", default: false
    t.boolean "deny", default: false
    t.boolean "remand", default: false
    t.boolean "dismiss", default: false
    t.string "description"
    t.boolean "from_vacols"
    t.datetime "deleted_at"
    t.string "notes"
    t.string "disposition"
    t.index ["deleted_at"], name: "index_worksheet_issues_on_deleted_at"
  end

  add_foreign_key "annotations", "users"
  add_foreign_key "api_views", "api_keys"
  add_foreign_key "appeals", "appeal_series"
  add_foreign_key "certifications", "users"
  add_foreign_key "legacy_appeals", "appeal_series"
  add_foreign_key "ramp_closed_appeals", "ramp_elections"
end
