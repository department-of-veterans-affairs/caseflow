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

ActiveRecord::Schema.define(version: 20190212142949) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "advance_on_docket_motions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "granted"
    t.bigint "person_id"
    t.string "reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["person_id"], name: "index_advance_on_docket_motions_on_person_id"
    t.index ["user_id"], name: "index_advance_on_docket_motions_on_user_id"
  end

  create_table "allocations", force: :cascade do |t|
    t.float "allocated_days", null: false
    t.datetime "created_at", null: false
    t.string "regional_office", null: false
    t.bigint "schedule_period_id", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_period_id"], name: "index_allocations_on_schedule_period_id"
  end

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.string "comment", null: false
    t.datetime "created_at"
    t.integer "document_id", null: false
    t.integer "page"
    t.date "relevant_date"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "x"
    t.integer "y"
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
    t.integer "api_key_id"
    t.datetime "created_at"
    t.string "source"
    t.string "vbms_id"
  end

  create_table "appeal_series", id: :serial, force: :cascade do |t|
    t.boolean "incomplete", default: false
    t.integer "merged_appeal_count"
  end

  create_table "appeal_views", id: :serial, force: :cascade do |t|
    t.integer "appeal_id", null: false
    t.string "appeal_type", null: false
    t.datetime "created_at", null: false
    t.datetime "last_viewed_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["appeal_type", "appeal_id", "user_id"], name: "index_appeal_views_on_appeal_type_and_appeal_id_and_user_id", unique: true
  end

  create_table "appeals", force: :cascade do |t|
    t.string "docket_type"
    t.datetime "established_at"
    t.datetime "establishment_attempted_at"
    t.string "establishment_error"
    t.datetime "establishment_last_submitted_at"
    t.datetime "establishment_processed_at"
    t.datetime "establishment_submitted_at"
    t.boolean "legacy_opt_in_approved"
    t.date "receipt_date"
    t.date "target_decision_date"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "veteran_file_number", null: false
    t.boolean "veteran_is_not_claimant"
    t.index ["veteran_file_number"], name: "index_appeals_on_veteran_file_number"
  end

  create_table "attorney_case_reviews", id: :serial, force: :cascade do |t|
    t.integer "attorney_id"
    t.datetime "created_at", null: false
    t.string "document_id"
    t.string "document_type"
    t.text "note"
    t.boolean "overtime", default: false
    t.integer "reviewing_judge_id"
    t.string "task_id"
    t.datetime "updated_at", null: false
    t.string "work_product"
  end

  create_table "available_hearing_locations", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "classification"
    t.datetime "created_at", null: false
    t.float "distance"
    t.string "facility_id"
    t.string "facility_type"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "veteran_file_number", null: false
    t.string "zip_code"
    t.index ["veteran_file_number"], name: "index_available_hearing_locations_on_veteran_file_number"
  end

  create_table "board_grant_effectuations", force: :cascade do |t|
    t.bigint "appeal_id", null: false
    t.string "contention_reference_id"
    t.bigint "decision_document_id"
    t.datetime "decision_sync_attempted_at"
    t.string "decision_sync_error"
    t.datetime "decision_sync_processed_at"
    t.datetime "decision_sync_submitted_at"
    t.bigint "end_product_establishment_id"
    t.bigint "granted_decision_issue_id", null: false
    t.datetime "last_submitted_at"
    t.index ["appeal_id"], name: "index_board_grant_effectuations_on_appeal_id"
    t.index ["decision_document_id"], name: "index_board_grant_effectuations_on_decision_document_id"
    t.index ["end_product_establishment_id"], name: "index_board_grant_effectuations_on_end_product_establishment_id"
    t.index ["granted_decision_issue_id"], name: "index_board_grant_effectuations_on_granted_decision_issue_id"
  end

  create_table "certification_cancellations", id: :serial, force: :cascade do |t|
    t.string "cancellation_reason"
    t.integer "certification_id"
    t.string "email"
    t.string "other_reason"
    t.index ["certification_id"], name: "index_certification_cancellations_on_certification_id", unique: true
  end

  create_table "certifications", id: :serial, force: :cascade do |t|
    t.boolean "already_certified"
    t.string "bgs_rep_address_line_1"
    t.string "bgs_rep_address_line_2"
    t.string "bgs_rep_address_line_3"
    t.string "bgs_rep_city"
    t.string "bgs_rep_country"
    t.string "bgs_rep_state"
    t.string "bgs_rep_zip"
    t.string "bgs_representative_name"
    t.string "bgs_representative_type"
    t.string "certification_date"
    t.string "certifying_office"
    t.string "certifying_official_name"
    t.string "certifying_official_title"
    t.string "certifying_username"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "form8_started_at"
    t.datetime "form9_matching_at"
    t.string "form9_type"
    t.boolean "hearing_change_doc_found_in_vbms"
    t.string "hearing_preference"
    t.boolean "loading_data"
    t.boolean "loading_data_failed"
    t.datetime "nod_matching_at"
    t.boolean "poa_correct_in_bgs"
    t.boolean "poa_correct_in_vacols"
    t.boolean "poa_matches"
    t.string "representative_name"
    t.string "representative_type"
    t.datetime "soc_matching_at"
    t.datetime "ssocs_matching_at"
    t.boolean "ssocs_required"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "v2"
    t.boolean "vacols_data_missing"
    t.string "vacols_hearing_preference"
    t.string "vacols_id"
    t.string "vacols_representative_name"
    t.string "vacols_representative_type"
    t.index ["user_id"], name: "index_certifications_on_user_id"
  end

  create_table "claim_establishments", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "decision_type"
    t.string "email_recipient"
    t.string "email_ro_id"
    t.string "ep_code"
    t.datetime "outcoding_date"
    t.integer "task_id"
    t.datetime "updated_at", null: false
  end

  create_table "claimants", force: :cascade do |t|
    t.string "participant_id", null: false
    t.string "payee_code"
    t.bigint "review_request_id", null: false
    t.string "review_request_type", null: false
    t.index ["review_request_type", "review_request_id"], name: "index_claimants_on_review_request"
  end

  create_table "claims_folder_searches", id: :serial, force: :cascade do |t|
    t.integer "appeal_id"
    t.string "appeal_type", null: false
    t.datetime "created_at"
    t.string "query"
    t.integer "user_id"
  end

  create_table "decision_documents", force: :cascade do |t|
    t.bigint "appeal_id", null: false
    t.datetime "attempted_at"
    t.string "citation_number", null: false
    t.datetime "created_at", null: false
    t.date "decision_date", null: false
    t.string "error"
    t.datetime "last_submitted_at"
    t.datetime "processed_at"
    t.string "redacted_document_location", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.datetime "uploaded_to_vbms_at"
    t.index ["appeal_id"], name: "index_decision_documents_on_appeal_id"
    t.index ["citation_number"], name: "index_decision_documents_on_citation_number", unique: true
  end

  create_table "decision_issues", force: :cascade do |t|
    t.string "benefit_type"
    t.date "caseflow_decision_date"
    t.integer "decision_review_id"
    t.string "decision_review_type"
    t.string "decision_text"
    t.string "description"
    t.string "diagnostic_code"
    t.string "disposition"
    t.date "end_product_last_action_date"
    t.string "participant_id", null: false
    t.datetime "profile_date"
    t.datetime "promulgation_date"
    t.string "rating_issue_reference_id"
    t.index ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_uniq_by_disposition_and_ref_id", unique: true
  end

  create_table "dispatch_tasks", id: :serial, force: :cascade do |t|
    t.string "aasm_state"
    t.integer "appeal_id", null: false
    t.datetime "assigned_at"
    t.string "comment"
    t.datetime "completed_at"
    t.integer "completion_status"
    t.datetime "created_at", null: false
    t.integer "lock_version"
    t.string "outgoing_reference_id"
    t.datetime "prepared_at"
    t.datetime "started_at"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "distributed_cases", force: :cascade do |t|
    t.string "case_id"
    t.integer "distribution_id"
    t.string "docket"
    t.integer "docket_index"
    t.boolean "genpop"
    t.string "genpop_query"
    t.boolean "priority"
    t.datetime "ready_at"
    t.integer "task_id"
    t.index ["case_id"], name: "index_distributed_cases_on_case_id", unique: true
  end

  create_table "distributions", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "judge_id"
    t.json "statistics"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "docket_snapshots", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "docket_count"
    t.date "latest_docket_month"
    t.datetime "updated_at"
  end

  create_table "docket_tracers", id: :serial, force: :cascade do |t|
    t.integer "ahead_and_ready_count"
    t.integer "ahead_count"
    t.integer "docket_snapshot_id"
    t.date "month"
    t.index ["docket_snapshot_id", "month"], name: "index_docket_tracers_on_docket_snapshot_id_and_month", unique: true
  end

  create_table "document_views", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.datetime "first_viewed_at"
    t.integer "user_id", null: false
    t.index ["document_id", "user_id"], name: "index_document_views_on_document_id_and_user_id", unique: true
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.boolean "category_medical"
    t.boolean "category_other"
    t.boolean "category_procedural"
    t.string "description"
    t.string "file_number"
    t.integer "previous_document_version_id"
    t.date "received_at"
    t.string "series_id"
    t.string "type"
    t.date "upload_date"
    t.string "vbms_document_id", null: false
    t.index ["file_number"], name: "index_documents_on_file_number"
    t.index ["series_id"], name: "index_documents_on_series_id"
    t.index ["vbms_document_id"], name: "index_documents_on_vbms_document_id", unique: true
  end

  create_table "documents_tags", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "tag_id", null: false
    t.index ["document_id", "tag_id"], name: "index_documents_tags_on_document_id_and_tag_id", unique: true
  end

  create_table "end_product_establishments", force: :cascade do |t|
    t.string "benefit_type_code"
    t.date "claim_date"
    t.string "claimant_participant_id"
    t.string "code"
    t.datetime "committed_at"
    t.string "development_item_reference_id"
    t.string "doc_reference_id"
    t.datetime "established_at"
    t.datetime "last_synced_at"
    t.string "modifier"
    t.string "payee_code", null: false
    t.string "reference_id"
    t.bigint "source_id", null: false
    t.string "source_type", null: false
    t.string "station"
    t.string "synced_status"
    t.integer "user_id"
    t.string "veteran_file_number", null: false
    t.index ["source_type", "source_id"], name: "index_end_product_establishments_on_source_type_and_source_id"
    t.index ["veteran_file_number"], name: "index_end_product_establishments_on_veteran_file_number"
  end

  create_table "form8s", id: :serial, force: :cascade do |t|
    t.string "_initial_appellant_name"
    t.string "_initial_appellant_relationship"
    t.string "_initial_hearing_requested"
    t.date "_initial_increased_rating_notification_date"
    t.string "_initial_insurance_loan_number"
    t.date "_initial_other_notification_date"
    t.string "_initial_representative_name"
    t.string "_initial_representative_type"
    t.date "_initial_service_connection_notification_date"
    t.date "_initial_soc_date"
    t.string "_initial_ssoc_required"
    t.string "_initial_veteran_name"
    t.string "agent_accredited"
    t.string "appellant_name"
    t.string "appellant_relationship"
    t.date "certification_date"
    t.integer "certification_id"
    t.string "certifying_office"
    t.string "certifying_official_name"
    t.string "certifying_official_title"
    t.string "certifying_official_title_specify_other"
    t.string "certifying_username"
    t.string "contested_claims_procedures_applicable"
    t.string "contested_claims_requirements_followed"
    t.datetime "created_at", null: false
    t.string "file_number"
    t.date "form9_date"
    t.string "form_646_not_of_record_explanation"
    t.string "form_646_of_record"
    t.string "hearing_held"
    t.string "hearing_preference"
    t.string "hearing_requested"
    t.string "hearing_requested_explanation"
    t.string "hearing_transcript_on_file"
    t.text "increased_rating_for"
    t.date "increased_rating_notification_date"
    t.string "insurance_loan_number"
    t.date "nod_date"
    t.text "other_for"
    t.date "other_notification_date"
    t.string "power_of_attorney"
    t.string "power_of_attorney_file"
    t.string "record_cf_or_xcf"
    t.string "record_clinical_rec"
    t.string "record_dental_f"
    t.string "record_dep_ed_f"
    t.string "record_hospital_cor"
    t.string "record_inactive_cf"
    t.string "record_insurance_f"
    t.string "record_loan_guar_f"
    t.string "record_other"
    t.text "record_other_explanation"
    t.string "record_outpatient_f"
    t.string "record_r_and_e_f"
    t.string "record_slides"
    t.string "record_tissue_blocks"
    t.string "record_training_sub_f"
    t.string "record_x_rays"
    t.text "remarks"
    t.string "representative_name"
    t.string "representative_type"
    t.string "representative_type_specify_other"
    t.text "service_connection_for"
    t.date "service_connection_notification_date"
    t.date "soc_date"
    t.date "ssoc_date_1"
    t.date "ssoc_date_2"
    t.date "ssoc_date_3"
    t.string "ssoc_required"
    t.datetime "updated_at", null: false
    t.string "vacols_id"
    t.string "veteran_name"
    t.index ["certification_id"], name: "index_form8s_on_certification_id"
  end

  create_table "global_admin_logins", id: :serial, force: :cascade do |t|
    t.string "admin_css_id"
    t.datetime "created_at"
    t.string "target_css_id"
    t.string "target_station_id"
    t.datetime "updated_at"
  end

  create_table "hearing_appeal_stream_snapshots", id: false, force: :cascade do |t|
    t.integer "appeal_id"
    t.datetime "created_at", null: false
    t.integer "hearing_id"
    t.index ["hearing_id", "appeal_id"], name: "index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids", unique: true
  end

  create_table "hearing_days", force: :cascade do |t|
    t.string "bva_poc"
    t.datetime "created_at", null: false
    t.string "created_by", null: false
    t.datetime "deleted_at"
    t.integer "judge_id"
    t.boolean "lock"
    t.text "notes"
    t.string "regional_office"
    t.string "request_type", null: false
    t.string "room", null: false
    t.date "scheduled_for", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", null: false
    t.index ["deleted_at"], name: "index_hearing_days_on_deleted_at"
  end

  create_table "hearing_issue_notes", force: :cascade do |t|
    t.boolean "allow", default: false
    t.boolean "deny", default: false
    t.boolean "dismiss", default: false
    t.bigint "hearing_id", null: false
    t.boolean "remand", default: false
    t.boolean "reopen", default: false
    t.bigint "request_issue_id", null: false
    t.string "worksheet_notes"
    t.index ["hearing_id"], name: "index_hearing_issue_notes_on_hearing_id"
    t.index ["request_issue_id"], name: "index_hearing_issue_notes_on_request_issue_id"
  end

  create_table "hearing_locations", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "classification"
    t.datetime "created_at", null: false
    t.float "distance"
    t.string "facility_id"
    t.string "facility_type"
    t.integer "hearing_id"
    t.string "hearing_type"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip_code"
  end

  create_table "hearing_views", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "hearing_id", null: false
    t.string "hearing_type"
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["hearing_id", "user_id", "hearing_type"], name: "index_hearing_views_on_hearing_id_and_user_id_and_hearing_type", unique: true
  end

  create_table "hearings", force: :cascade do |t|
    t.integer "appeal_id", null: false
    t.string "bva_poc"
    t.string "disposition"
    t.boolean "evidence_window_waived"
    t.integer "hearing_day_id", null: false
    t.integer "judge_id"
    t.string "military_service"
    t.string "notes"
    t.boolean "prepped"
    t.string "representative_name"
    t.string "room"
    t.time "scheduled_time", null: false
    t.text "summary"
    t.boolean "transcript_requested"
    t.date "transcript_sent_date"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "witness"
  end

  create_table "higher_level_reviews", force: :cascade do |t|
    t.string "benefit_type"
    t.datetime "establishment_attempted_at"
    t.string "establishment_error"
    t.datetime "establishment_last_submitted_at"
    t.datetime "establishment_processed_at"
    t.datetime "establishment_submitted_at"
    t.boolean "informal_conference"
    t.boolean "legacy_opt_in_approved"
    t.date "receipt_date"
    t.boolean "same_office"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "veteran_file_number", null: false
    t.boolean "veteran_is_not_claimant"
    t.index ["veteran_file_number"], name: "index_higher_level_reviews_on_veteran_file_number"
  end

  create_table "intakes", id: :serial, force: :cascade do |t|
    t.string "cancel_other"
    t.string "cancel_reason"
    t.datetime "completed_at"
    t.datetime "completion_started_at"
    t.string "completion_status"
    t.integer "detail_id"
    t.string "detail_type"
    t.string "error_code"
    t.datetime "started_at"
    t.string "type"
    t.integer "user_id", null: false
    t.string "veteran_file_number"
    t.index ["type", "veteran_file_number"], name: "unique_index_to_avoid_duplicate_intakes", unique: true, where: "(completed_at IS NULL)"
    t.index ["type"], name: "index_intakes_on_type"
    t.index ["user_id"], name: "index_intakes_on_user_id"
    t.index ["user_id"], name: "unique_index_to_avoid_multiple_intakes", unique: true, where: "(completed_at IS NULL)"
    t.index ["veteran_file_number"], name: "index_intakes_on_veteran_file_number"
  end

  create_table "judge_case_reviews", force: :cascade do |t|
    t.text "areas_for_improvement", default: [], array: true
    t.integer "attorney_id"
    t.text "comment"
    t.string "complexity"
    t.datetime "created_at", null: false
    t.text "factors_not_considered", default: [], array: true
    t.integer "judge_id"
    t.string "location"
    t.boolean "one_touch_initiative"
    t.string "quality"
    t.string "task_id"
    t.datetime "updated_at", null: false
  end

  create_table "legacy_appeals", force: :cascade do |t|
    t.bigint "appeal_series_id"
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.boolean "dic_death_or_accrued_benefits_united_states", default: false
    t.string "dispatched_to_station"
    t.boolean "education_gi_bill_dependents_educational_assistance_scholars", default: false
    t.boolean "foreign_claim_compensation_claims_dual_claims_appeals", default: false
    t.boolean "foreign_pension_dic_all_other_foreign_countries", default: false
    t.boolean "foreign_pension_dic_mexico_central_and_south_america_caribb", default: false
    t.boolean "hearing_including_travel_board_video_conference", default: false
    t.boolean "home_loan_guaranty", default: false
    t.boolean "incarcerated_veterans", default: false
    t.boolean "insurance", default: false
    t.boolean "issues_pulled"
    t.boolean "manlincon_compliance", default: false
    t.boolean "mustard_gas", default: false
    t.boolean "national_cemetery_administration", default: false
    t.boolean "nonrating_issue", default: false
    t.boolean "pension_united_states", default: false
    t.boolean "private_attorney_or_agent", default: false
    t.boolean "radiation", default: false
    t.boolean "rice_compliance", default: false
    t.boolean "spina_bifida", default: false
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.string "vacols_id", null: false
    t.boolean "vamc", default: false
    t.string "vbms_id"
    t.boolean "vocational_rehab", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.index ["appeal_series_id"], name: "index_legacy_appeals_on_appeal_series_id"
    t.index ["vacols_id"], name: "index_legacy_appeals_on_vacols_id", unique: true
  end

  create_table "legacy_hearings", force: :cascade do |t|
    t.integer "appeal_id"
    t.string "military_service"
    t.boolean "prepped"
    t.text "summary"
    t.integer "user_id"
    t.string "vacols_id", null: false
    t.string "witness"
  end

  create_table "legacy_issue_optins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error"
    t.datetime "optin_processed_at"
    t.string "original_disposition_code"
    t.date "original_disposition_date"
    t.bigint "request_issue_id", null: false
    t.datetime "rollback_created_at"
    t.datetime "rollback_processed_at"
    t.datetime "updated_at", null: false
    t.index ["request_issue_id"], name: "index_legacy_issue_optins_on_request_issue_id"
  end

  create_table "non_availabilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "object_identifier", null: false
    t.bigint "schedule_period_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_period_id"], name: "index_non_availabilities_on_schedule_period_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "participant_id"
    t.string "role"
    t.string "type"
    t.string "url"
  end

  create_table "organizations_users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at"
    t.integer "organization_id"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_organizations_users_on_user_id_and_organization_id", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "participant_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ramp_closed_appeals", id: :serial, force: :cascade do |t|
    t.datetime "closed_on"
    t.date "nod_date"
    t.string "partial_closure_issue_sequence_ids", array: true
    t.integer "ramp_election_id"
    t.string "vacols_id", null: false
  end

  create_table "ramp_election_rollbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ramp_election_id"
    t.string "reason"
    t.string "reopened_vacols_ids", array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["ramp_election_id"], name: "index_ramp_election_rollbacks_on_ramp_election_id"
    t.index ["user_id"], name: "index_ramp_election_rollbacks_on_user_id"
  end

  create_table "ramp_elections", id: :serial, force: :cascade do |t|
    t.string "end_product_reference_id"
    t.string "end_product_status"
    t.datetime "end_product_status_last_synced_at"
    t.datetime "established_at"
    t.datetime "establishment_attempted_at"
    t.string "establishment_error"
    t.datetime "establishment_processed_at"
    t.datetime "establishment_submitted_at"
    t.date "notice_date"
    t.string "option_selected"
    t.date "receipt_date"
    t.string "veteran_file_number", null: false
    t.index ["veteran_file_number"], name: "index_ramp_elections_on_veteran_file_number"
  end

  create_table "ramp_issues", id: :serial, force: :cascade do |t|
    t.string "contention_reference_id"
    t.string "description", null: false
    t.integer "review_id", null: false
    t.string "review_type", null: false
    t.integer "source_issue_id"
    t.index ["review_type", "review_id"], name: "index_ramp_issues_on_review_type_and_review_id"
  end

  create_table "ramp_refilings", id: :serial, force: :cascade do |t|
    t.string "appeal_docket"
    t.string "end_product_reference_id"
    t.datetime "established_at"
    t.datetime "establishment_attempted_at"
    t.string "establishment_error"
    t.datetime "establishment_processed_at"
    t.datetime "establishment_submitted_at"
    t.boolean "has_ineligible_issue"
    t.string "option_selected"
    t.date "receipt_date"
    t.string "veteran_file_number", null: false
    t.index ["veteran_file_number"], name: "index_ramp_refilings_on_veteran_file_number"
  end

  create_table "reader_users", id: :serial, force: :cascade do |t|
    t.datetime "documents_fetched_at"
    t.integer "user_id", null: false
    t.index ["documents_fetched_at"], name: "index_reader_users_on_documents_fetched_at"
    t.index ["user_id"], name: "index_reader_users_on_user_id", unique: true
  end

  create_table "remand_reasons", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "decision_issue_id"
    t.boolean "post_aoj"
    t.bigint "request_issue_id"
    t.datetime "updated_at", null: false
    t.index ["decision_issue_id"], name: "index_remand_reasons_on_decision_issue_id"
    t.index ["request_issue_id"], name: "index_remand_reasons_on_request_issue_id"
  end

  create_table "request_decision_issues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "decision_issue_id"
    t.integer "request_issue_id"
    t.datetime "updated_at", null: false
    t.index ["request_issue_id", "decision_issue_id"], name: "index_on_request_issue_id_and_decision_issue_id", unique: true
  end

  create_table "request_issues", force: :cascade do |t|
    t.string "benefit_type", null: false
    t.datetime "closed_at"
    t.string "closed_status"
    t.integer "contention_reference_id"
    t.integer "contested_decision_issue_id"
    t.string "contested_issue_description"
    t.string "contested_rating_issue_diagnostic_code"
    t.string "contested_rating_issue_disability_code"
    t.string "contested_rating_issue_profile_date"
    t.string "contested_rating_issue_reference_id"
    t.datetime "created_at"
    t.date "decision_date"
    t.bigint "decision_review_id"
    t.string "decision_review_type"
    t.datetime "decision_sync_attempted_at"
    t.string "decision_sync_error"
    t.datetime "decision_sync_processed_at"
    t.datetime "decision_sync_submitted_at"
    t.string "description"
    t.string "disposition"
    t.integer "end_product_establishment_id"
    t.bigint "ineligible_due_to_id"
    t.string "ineligible_reason"
    t.boolean "is_unidentified"
    t.string "issue_category"
    t.datetime "last_submitted_at"
    t.string "nonrating_issue_description"
    t.text "notes"
    t.integer "parent_request_issue_id"
    t.string "ramp_claim_id"
    t.datetime "rating_issue_associated_at"
    t.datetime "rating_issue_profile_date"
    t.string "rating_issue_reference_id"
    t.datetime "removed_at"
    t.bigint "review_request_id"
    t.string "review_request_type"
    t.string "unidentified_issue_text"
    t.boolean "untimely_exemption"
    t.text "untimely_exemption_notes"
    t.string "vacols_id"
    t.integer "vacols_sequence_id"
    t.string "veteran_participant_id"
    t.index ["contention_reference_id", "removed_at"], name: "index_request_issues_on_contention_reference_id_and_removed_at", unique: true
    t.index ["contested_decision_issue_id"], name: "index_request_issues_on_contested_decision_issue_id"
    t.index ["contested_rating_issue_reference_id"], name: "index_request_issues_on_contested_rating_issue_reference_id"
    t.index ["decision_review_type", "decision_review_id"], name: "index_request_issues_on_decision_review_columns"
    t.index ["end_product_establishment_id"], name: "index_request_issues_on_end_product_establishment_id"
    t.index ["ineligible_due_to_id"], name: "index_request_issues_on_ineligible_due_to_id"
    t.index ["parent_request_issue_id"], name: "index_request_issues_on_parent_request_issue_id"
    t.index ["rating_issue_reference_id"], name: "index_request_issues_on_rating_issue_reference_id"
    t.index ["review_request_type", "review_request_id"], name: "index_request_issues_on_review_request"
  end

  create_table "request_issues_updates", force: :cascade do |t|
    t.integer "after_request_issue_ids", null: false, array: true
    t.datetime "attempted_at"
    t.integer "before_request_issue_ids", null: false, array: true
    t.string "error"
    t.datetime "last_submitted_at"
    t.datetime "processed_at"
    t.bigint "review_id", null: false
    t.string "review_type", null: false
    t.datetime "submitted_at"
    t.bigint "user_id", null: false
    t.index ["review_type", "review_id"], name: "index_request_issues_updates_on_review_type_and_review_id"
    t.index ["user_id"], name: "index_request_issues_updates_on_user_id"
  end

  create_table "schedule_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "file_name", null: false
    t.boolean "finalized"
    t.date "start_date", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_schedule_periods_on_user_id"
  end

  create_table "special_issue_lists", force: :cascade do |t|
    t.bigint "appeal_id"
    t.string "appeal_type"
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.boolean "dic_death_or_accrued_benefits_united_states", default: false
    t.boolean "education_gi_bill_dependents_educational_assistance_scholars", default: false
    t.boolean "foreign_claim_compensation_claims_dual_claims_appeals", default: false
    t.boolean "foreign_pension_dic_all_other_foreign_countries", default: false
    t.boolean "foreign_pension_dic_mexico_central_and_south_america_caribb", default: false
    t.boolean "hearing_including_travel_board_video_conference", default: false
    t.boolean "home_loan_guaranty", default: false
    t.boolean "incarcerated_veterans", default: false
    t.boolean "insurance", default: false
    t.boolean "manlincon_compliance", default: false
    t.boolean "mustard_gas", default: false
    t.boolean "national_cemetery_administration", default: false
    t.boolean "nonrating_issue", default: false
    t.boolean "pension_united_states", default: false
    t.boolean "private_attorney_or_agent", default: false
    t.boolean "radiation", default: false
    t.boolean "rice_compliance", default: false
    t.boolean "spina_bifida", default: false
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.boolean "vamc", default: false
    t.boolean "vocational_rehab", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.index ["appeal_type", "appeal_id"], name: "index_special_issue_lists_on_appeal_type_and_appeal_id"
  end

  create_table "supplemental_claims", force: :cascade do |t|
    t.string "benefit_type"
    t.bigint "decision_review_remanded_id"
    t.string "decision_review_remanded_type"
    t.datetime "establishment_attempted_at"
    t.string "establishment_error"
    t.datetime "establishment_last_submitted_at"
    t.datetime "establishment_processed_at"
    t.datetime "establishment_submitted_at"
    t.boolean "legacy_opt_in_approved"
    t.date "receipt_date"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "veteran_file_number", null: false
    t.boolean "veteran_is_not_claimant"
    t.index ["decision_review_remanded_type", "decision_review_remanded_id"], name: "index_decision_issues_on_decision_review_remanded"
    t.index ["veteran_file_number"], name: "index_supplemental_claims_on_veteran_file_number"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["text"], name: "index_tags_on_text", unique: true
  end

  create_table "task_timers", force: :cascade do |t|
    t.datetime "attempted_at"
    t.datetime "created_at", null: false
    t.string "error"
    t.datetime "last_submitted_at"
    t.datetime "processed_at"
    t.datetime "submitted_at"
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_task_timers_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.text "action"
    t.integer "appeal_id", null: false
    t.string "appeal_type", null: false
    t.datetime "assigned_at"
    t.integer "assigned_by_id"
    t.integer "assigned_to_id"
    t.string "assigned_to_type", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "instructions", default: [], array: true
    t.integer "on_hold_duration"
    t.integer "parent_id"
    t.datetime "placed_on_hold_at"
    t.datetime "started_at"
    t.string "status", default: "assigned"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["appeal_type", "appeal_id"], name: "index_tasks_on_appeal_type_and_appeal_id"
    t.index ["assigned_to_type", "assigned_to_id"], name: "index_tasks_on_assigned_to_type_and_assigned_to_id"
  end

  create_table "team_quotas", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_count"
    t.index ["date", "task_type"], name: "index_team_quotas_on_date_and_task_type", unique: true
  end

  create_table "transcriptions", force: :cascade do |t|
    t.date "expected_return_date"
    t.bigint "hearing_id"
    t.date "problem_notice_sent_date"
    t.string "problem_type"
    t.string "requested_remedy"
    t.date "sent_to_transcriber_date"
    t.string "task_number"
    t.string "transcriber"
    t.date "uploaded_to_vbms_date"
    t.index ["hearing_id"], name: "index_transcriptions_on_hearing_id"
  end

  create_table "user_quotas", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "locked_task_count"
    t.integer "team_quota_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["team_quota_id", "user_id"], name: "index_user_quotas_on_team_quota_id_and_user_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "css_id", null: false
    t.string "email"
    t.string "full_name"
    t.string "roles", array: true
    t.string "selected_regional_office"
    t.string "station_id", null: false
    t.index ["station_id", "css_id"], name: "index_users_on_station_id_and_css_id", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "veterans", force: :cascade do |t|
    t.string "closest_regional_office"
    t.string "file_number", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "name_suffix"
    t.string "participant_id"
    t.index ["file_number"], name: "index_veterans_on_file_number", unique: true
  end

  create_table "worksheet_issues", id: :serial, force: :cascade do |t|
    t.boolean "allow", default: false
    t.integer "appeal_id"
    t.datetime "deleted_at"
    t.boolean "deny", default: false
    t.string "description"
    t.boolean "dismiss", default: false
    t.string "disposition"
    t.boolean "from_vacols"
    t.string "notes"
    t.boolean "omo", default: false
    t.boolean "remand", default: false
    t.boolean "reopen", default: false
    t.string "vacols_sequence_id"
    t.index ["deleted_at"], name: "index_worksheet_issues_on_deleted_at"
  end

  add_foreign_key "annotations", "users"
  add_foreign_key "api_views", "api_keys"
  add_foreign_key "certifications", "users"
  add_foreign_key "legacy_appeals", "appeal_series"
  add_foreign_key "ramp_closed_appeals", "ramp_elections"
end
