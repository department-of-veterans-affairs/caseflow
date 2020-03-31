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

ActiveRecord::Schema.define(version: 2020_03_27_174629) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "advance_on_docket_motions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "granted", comment: "Whether VLJ has determined that there is sufficient cause to fast-track an appeal, i.e. grant or deny the motion to AOD."
    t.bigint "person_id", comment: "Appellant ID"
    t.string "reason", comment: "VLJ's rationale for their decision on motion to AOD."
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["granted"], name: "index_advance_on_docket_motions_on_granted"
    t.index ["person_id"], name: "index_advance_on_docket_motions_on_person_id"
    t.index ["updated_at"], name: "index_advance_on_docket_motions_on_updated_at"
    t.index ["user_id"], name: "index_advance_on_docket_motions_on_user_id"
  end

  create_table "allocations", force: :cascade do |t|
    t.float "allocated_days", null: false
    t.datetime "created_at", null: false
    t.string "regional_office", null: false
    t.bigint "schedule_period_id", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_period_id"], name: "index_allocations_on_schedule_period_id"
    t.index ["updated_at"], name: "index_allocations_on_updated_at"
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
    t.datetime "created_at"
    t.string "key_digest", null: false
    t.datetime "updated_at"
    t.index ["consumer_name"], name: "index_api_keys_on_consumer_name", unique: true
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["updated_at"], name: "index_api_keys_on_updated_at"
  end

  create_table "api_views", id: :serial, force: :cascade do |t|
    t.integer "api_key_id"
    t.datetime "created_at"
    t.string "source"
    t.datetime "updated_at"
    t.string "vbms_id"
  end

  create_table "appeal_series", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "incomplete", default: false
    t.integer "merged_appeal_count"
    t.datetime "updated_at"
    t.index ["updated_at"], name: "index_appeal_series_on_updated_at"
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

  create_table "appeals", comment: "Decision reviews intaken for AMA appeals to the board (also known as a notice of disagreement).", force: :cascade do |t|
    t.string "closest_regional_office", comment: "The code for the regional office closest to the Veteran on the appeal."
    t.datetime "created_at"
    t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
    t.string "docket_type", comment: "The docket type selected by the Veteran on their appeal form, which can be hearing, evidence submission, or direct review."
    t.datetime "established_at", comment: "Timestamp for when the appeal has successfully been intaken into Caseflow by the user."
    t.datetime "establishment_attempted_at", comment: "Timestamp for when the appeal's establishment was last attempted."
    t.datetime "establishment_canceled_at", comment: "Timestamp when job was abandoned"
    t.string "establishment_error", comment: "The error message if attempting to establish the appeal resulted in an error. This gets cleared once the establishment is successful."
    t.datetime "establishment_last_submitted_at", comment: "Timestamp for when the the job is eligible to run (can be reset to restart the job)."
    t.datetime "establishment_processed_at", comment: "Timestamp for when the establishment has succeeded in processing."
    t.datetime "establishment_submitted_at", comment: "Timestamp for when the the intake was submitted for asynchronous processing."
    t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
    t.string "poa_participant_id", comment: "Used to identify the power of attorney (POA) at the time the appeal was dispatched to BVA. Sometimes the POA changes in BGS after the fact, and BGS only returns the current representative."
    t.date "receipt_date", comment: "Receipt date of the appeal form. Used to determine which issues are within the timeliness window to be appealed. Only issues decided prior to the receipt date will show up as contestable issues."
    t.string "stream_docket_number", comment: "Multiple appeals with the same docket number indicate separate appeal streams, mimicking the structure of legacy appeals."
    t.string "stream_type", default: "Original", comment: "When multiple appeals have the same docket number, they are differentiated by appeal stream type, depending on the work being done on each appeal."
    t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
    t.datetime "updated_at"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false, comment: "The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid. This allows a single ID to determine an appeal whether it is a legacy appeal or an AMA appeal."
    t.string "veteran_file_number", null: false, comment: "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
    t.index ["docket_type"], name: "index_appeals_on_docket_type"
    t.index ["established_at"], name: "index_appeals_on_established_at"
    t.index ["updated_at"], name: "index_appeals_on_updated_at"
    t.index ["uuid"], name: "index_appeals_on_uuid"
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
    t.boolean "untimely_evidence", default: false
    t.datetime "updated_at", null: false
    t.string "work_product"
    t.index ["task_id"], name: "index_attorney_case_reviews_on_task_id"
    t.index ["updated_at"], name: "index_attorney_case_reviews_on_updated_at"
  end

  create_table "available_hearing_locations", force: :cascade do |t|
    t.string "address"
    t.integer "appeal_id"
    t.string "appeal_type"
    t.string "city"
    t.string "classification"
    t.datetime "created_at", null: false
    t.float "distance"
    t.string "facility_id"
    t.string "facility_type"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "veteran_file_number"
    t.string "zip_code"
    t.index ["appeal_id", "appeal_type"], name: "index_available_hearing_locations_on_appeal_id_and_appeal_type"
    t.index ["updated_at"], name: "index_available_hearing_locations_on_updated_at"
    t.index ["veteran_file_number"], name: "index_available_hearing_locations_on_veteran_file_number"
  end

  create_table "board_grant_effectuations", comment: "Represents the work item of updating records in response to a granted issue on a Board appeal. Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.", force: :cascade do |t|
    t.bigint "appeal_id", null: false, comment: "The ID of the appeal containing the granted issue being effectuated."
    t.string "contention_reference_id", comment: "The ID of the contention created in VBMS. Indicates successful creation of the contention. If the EP has been rated, this contention could have been connected to a rating issue. That connection is used to map the rating issue back to the decision issue."
    t.datetime "created_at"
    t.bigint "decision_document_id", comment: "The ID of the decision document which triggered this effectuation."
    t.datetime "decision_sync_attempted_at", comment: "When the EP is cleared, an asyncronous job attempts to map the resulting rating issue back to the decision issue. Timestamp representing the time the job was last attempted."
    t.datetime "decision_sync_canceled_at", comment: "Timestamp when job was abandoned"
    t.string "decision_sync_error", comment: "Async job processing last error message. See description for decision_sync_attempted_at for the decision sync job description."
    t.datetime "decision_sync_last_submitted_at", comment: "Timestamp for when the the job is eligible to run (can be reset to restart the job)."
    t.datetime "decision_sync_processed_at", comment: "Async job processing completed timestamp. See description for decision_sync_attempted_at for the decision sync job description."
    t.datetime "decision_sync_submitted_at", comment: "Async job processing start timestamp. See description for decision_sync_attempted_at for the decision sync job description."
    t.bigint "end_product_establishment_id", comment: "The ID of the end product establishment created for this board grant effectuation."
    t.bigint "granted_decision_issue_id", null: false, comment: "The ID of the granted decision issue."
    t.datetime "last_submitted_at", comment: "Async job processing most recent start timestamp"
    t.datetime "updated_at"
    t.index ["appeal_id"], name: "index_board_grant_effectuations_on_appeal_id"
    t.index ["contention_reference_id"], name: "index_board_grant_effectuations_on_contention_reference_id", unique: true
    t.index ["decision_document_id"], name: "index_board_grant_effectuations_on_decision_document_id"
    t.index ["end_product_establishment_id"], name: "index_board_grant_effectuations_on_end_product_establishment_id"
    t.index ["granted_decision_issue_id"], name: "index_board_grant_effectuations_on_granted_decision_issue_id"
    t.index ["updated_at"], name: "index_board_grant_effectuations_on_updated_at"
  end

  create_table "cached_appeal_attributes", id: false, force: :cascade do |t|
    t.integer "appeal_id"
    t.string "appeal_type"
    t.string "assignee_label", comment: "Who is currently most responsible for the appeal"
    t.string "case_type", comment: "The case type, i.e. original, post remand, CAVC remand, etc"
    t.string "closest_regional_office_city", comment: "Closest regional office to the veteran"
    t.string "closest_regional_office_key", comment: "Closest regional office to the veteran in 4 character key"
    t.datetime "created_at"
    t.string "docket_number"
    t.string "docket_type"
    t.boolean "is_aod", comment: "Whether the case is Advanced on Docket"
    t.integer "issue_count", comment: "Number of issues on the appeal."
    t.string "power_of_attorney_name", comment: "'Firstname Lastname' of power of attorney"
    t.string "suggested_hearing_location", comment: "Suggested hearing location in 'City, State (Facility Type)' format"
    t.datetime "updated_at"
    t.string "vacols_id"
    t.string "veteran_name", comment: "'LastName, FirstName' of the veteran"
    t.index ["appeal_id", "appeal_type"], name: "index_cached_appeal_attributes_on_appeal_id_and_appeal_type", unique: true
    t.index ["updated_at"], name: "index_cached_appeal_attributes_on_updated_at"
    t.index ["vacols_id"], name: "index_cached_appeal_attributes_on_vacols_id", unique: true
  end

  create_table "cached_user_attributes", id: false, comment: "VACOLS cached staff table attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "sactive", null: false
    t.string "sattyid"
    t.string "sdomainid", null: false
    t.string "slogid", null: false
    t.string "smemgrp", limit: 8
    t.string "stafkey", null: false
    t.string "stitle", limit: 16
    t.string "svlj"
    t.datetime "updated_at", null: false
    t.index ["sdomainid"], name: "index_cached_user_attributes_on_sdomainid", unique: true
    t.index ["updated_at"], name: "index_cached_user_attributes_on_updated_at"
  end

  create_table "certification_cancellations", id: :serial, force: :cascade do |t|
    t.string "cancellation_reason"
    t.integer "certification_id"
    t.datetime "created_at"
    t.string "email"
    t.string "other_reason"
    t.datetime "updated_at"
    t.index ["certification_id"], name: "index_certification_cancellations_on_certification_id", unique: true
    t.index ["updated_at"], name: "index_certification_cancellations_on_updated_at"
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
    t.index ["updated_at"], name: "index_certifications_on_updated_at"
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
    t.index ["updated_at"], name: "index_claim_establishments_on_updated_at"
  end

  create_table "claimants", comment: "This table bridges decision reviews to participants when the participant is listed as a claimant on the decision review. A participant can be a claimant on multiple decision reviews.", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "decision_review_id", comment: "The ID of the decision review the claimant is on."
    t.string "decision_review_type", comment: "The type of decision review the claimant is on."
    t.string "participant_id", null: false, comment: "The participant ID of the claimant."
    t.string "payee_code", comment: "The payee_code for the claimant, if applicable. payee_code is required when the claim is processed in VBMS."
    t.datetime "updated_at"
    t.index ["decision_review_type", "decision_review_id"], name: "index_claimants_on_decision_review_type_and_decision_review_id"
    t.index ["participant_id"], name: "index_claimants_on_participant_id"
    t.index ["updated_at"], name: "index_claimants_on_updated_at"
  end

  create_table "claims_folder_searches", id: :serial, force: :cascade do |t|
    t.integer "appeal_id"
    t.string "appeal_type", null: false
    t.datetime "created_at"
    t.string "query"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["appeal_id", "appeal_type"], name: "index_claims_folder_searches_on_appeal_id_and_appeal_type"
    t.index ["updated_at"], name: "index_claims_folder_searches_on_updated_at"
    t.index ["user_id"], name: "index_claims_folder_searches_on_user_id"
  end

  create_table "decision_documents", force: :cascade do |t|
    t.bigint "appeal_id", null: false
    t.string "appeal_type"
    t.datetime "attempted_at"
    t.datetime "canceled_at", comment: "Timestamp when job was abandoned"
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
    t.index ["updated_at"], name: "index_decision_documents_on_updated_at"
  end

  create_table "decision_issues", comment: "Issues that represent a decision made on a decision review.", force: :cascade do |t|
    t.string "benefit_type", comment: "Classification of the benefit being decided on. Maps 1 to 1 to VA lines of business, and typically used to know which line of business the decision correlates to."
    t.date "caseflow_decision_date", comment: "This is a decision date for decision issues where decisions are entered in Caseflow, such as for appeals or for decision reviews with a business line that is not processed in VBMS."
    t.datetime "created_at", comment: "Automatic timestamp when row was created."
    t.integer "decision_review_id", comment: "ID of the decision review the decision was made on."
    t.string "decision_review_type", comment: "Type of the decision review the decision was made on."
    t.string "decision_text", comment: "If decision resulted in a change to a rating, the rating issue's decision text."
    t.datetime "deleted_at"
    t.string "description", comment: "Optional description that the user can input for decisions made in Caseflow."
    t.string "diagnostic_code", comment: "If a decision resulted in a rating, this is the rating issue's diagnostic code."
    t.string "disposition", comment: "The disposition for a decision issue. Dispositions made in Caseflow and dispositions made in VBMS can have different values."
    t.date "end_product_last_action_date", comment: "After an end product gets synced with a status of CLR (cleared), the end product's last_action_date is saved on any decision issues that are created as a result. This is used as a proxy for decision date for non-rating issues that are processed in VBMS because they don't have a rating profile date, and the exact decision date is not available."
    t.string "participant_id", null: false, comment: "The Veteran's participant id."
    t.string "rating_issue_reference_id", comment: "Identifies the specific issue on the rating that resulted from the decision issue (a rating can have multiple issues). This is unique per rating issue."
    t.datetime "rating_profile_date", comment: "The profile date of the rating that a decision issue resulted in (if applicable). The profile_date is used as an identifier for the rating, and is the date that most closely maps to what the Veteran writes down as the decision date."
    t.datetime "rating_promulgation_date", comment: "The promulgation date of the rating that a decision issue resulted in (if applicable). It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review."
    t.datetime "updated_at"
    t.index ["decision_review_id", "decision_review_type"], name: "index_decision_issues_decision_review"
    t.index ["deleted_at"], name: "index_decision_issues_on_deleted_at"
    t.index ["disposition"], name: "index_decision_issues_on_disposition"
    t.index ["rating_issue_reference_id", "disposition", "participant_id"], name: "decision_issues_uniq_by_disposition_and_ref_id", unique: true
    t.index ["updated_at"], name: "index_decision_issues_on_updated_at"
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
    t.index ["updated_at"], name: "index_dispatch_tasks_on_updated_at"
    t.index ["user_id"], name: "index_dispatch_tasks_on_user_id"
  end

  create_table "distributed_cases", force: :cascade do |t|
    t.string "case_id"
    t.datetime "created_at"
    t.integer "distribution_id"
    t.string "docket"
    t.integer "docket_index"
    t.boolean "genpop"
    t.string "genpop_query"
    t.boolean "priority"
    t.datetime "ready_at"
    t.integer "task_id"
    t.datetime "updated_at"
    t.index ["case_id"], name: "index_distributed_cases_on_case_id", unique: true
    t.index ["updated_at"], name: "index_distributed_cases_on_updated_at"
  end

  create_table "distributions", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "errored_at", comment: "when the Distribution job suffered an error"
    t.integer "judge_id"
    t.datetime "started_at", comment: "when the Distribution job commenced"
    t.json "statistics"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["updated_at"], name: "index_distributions_on_updated_at"
  end

  create_table "docket_snapshots", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "docket_count"
    t.date "latest_docket_month"
    t.datetime "updated_at"
    t.index ["updated_at"], name: "index_docket_snapshots_on_updated_at"
  end

  create_table "docket_tracers", id: :serial, force: :cascade do |t|
    t.integer "ahead_and_ready_count"
    t.integer "ahead_count"
    t.datetime "created_at"
    t.integer "docket_snapshot_id"
    t.date "month"
    t.datetime "updated_at"
    t.index ["docket_snapshot_id", "month"], name: "index_docket_tracers_on_docket_snapshot_id_and_month", unique: true
    t.index ["updated_at"], name: "index_docket_tracers_on_updated_at"
  end

  create_table "document_views", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "document_id", null: false
    t.datetime "first_viewed_at"
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["document_id", "user_id"], name: "index_document_views_on_document_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_document_views_on_user_id"
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.boolean "category_medical"
    t.boolean "category_other"
    t.boolean "category_procedural"
    t.datetime "created_at"
    t.string "description"
    t.string "file_number"
    t.integer "previous_document_version_id"
    t.date "received_at"
    t.string "series_id"
    t.string "type"
    t.datetime "updated_at"
    t.date "upload_date"
    t.string "vbms_document_id", null: false
    t.index ["file_number"], name: "index_documents_on_file_number"
    t.index ["series_id"], name: "index_documents_on_series_id"
    t.index ["vbms_document_id"], name: "index_documents_on_vbms_document_id", unique: true
  end

  create_table "documents_tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "document_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at"
    t.index ["document_id", "tag_id"], name: "index_documents_tags_on_document_id_and_tag_id", unique: true
  end

  create_table "end_product_code_updates", comment: "Caseflow establishes end products in VBMS with specific end product codes. If that code is changed outside of Caseflow, that is tracked here.", force: :cascade do |t|
    t.string "code", null: false, comment: "The new end product code, if it has changed since last checked."
    t.datetime "created_at", null: false
    t.bigint "end_product_establishment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["end_product_establishment_id"], name: "index_end_product_code_updates_on_end_product_establishment_id"
    t.index ["updated_at"], name: "index_end_product_code_updates_on_updated_at"
  end

  create_table "end_product_establishments", comment: "Represents end products that have been, or need to be established by Caseflow. Used to track the status of those end products as they are processed in VBMS and/or SHARE.", force: :cascade do |t|
    t.string "benefit_type_code", comment: "1 if the Veteran is alive, and 2 if the Veteran is deceased. Not to be confused with benefit_type, which is unrelated."
    t.date "claim_date", comment: "The claim_date for end product established."
    t.string "claimant_participant_id", comment: "The participant ID of the claimant submitted on the end product."
    t.string "code", comment: "The end product code, which determines the type of end product that is established. For example, it can contain information about whether it is rating, nonrating, compensation, pension, created automatically due to a Duty to Assist Error, and more."
    t.datetime "committed_at", comment: "Timestamp indicating other actions performed as part of a larger atomic operation containing the end product establishment, such as creating contentions, are also complete."
    t.datetime "created_at"
    t.string "development_item_reference_id", comment: "When a Veteran requests an informal conference with their higher level review, a tracked item is created. This stores the ID of the of the tracked item, it is also used to indicate the success of creating the tracked item."
    t.string "doc_reference_id", comment: "When a Veteran requests an informal conference, a claimant letter is generated. This stores the document ID of the claimant letter, and is also used to track the success of creating the claimant letter."
    t.datetime "established_at", comment: "Timestamp for when the end product was established."
    t.datetime "last_synced_at", comment: "The time that the status of the end product was last synced with BGS. The end product is synced until it is canceled or cleared, meaning it is no longer active."
    t.boolean "limited_poa_access", comment: "Indicates whether the limited Power of Attorney has access to view documents"
    t.string "limited_poa_code", comment: "The limited Power of Attorney code, which indicates whether the claim has a POA specifically for this claim, which can be different than the Veteran's POA"
    t.string "modifier", comment: "The end product modifier. For higher level reviews, the modifiers range from 030-039. For supplemental claims, they range from 040-049. The same modifier cannot be used twice for an active end product per Veteran. Once an end product is no longer active, the modifier can be used again."
    t.string "payee_code", null: false, comment: "The payee_code of the claimant submitted for this end product."
    t.string "reference_id", comment: "The claim_id of the end product, which is stored after the end product is successfully established in VBMS."
    t.bigint "source_id", null: false, comment: "The ID of the source that resulted in this end product establishment."
    t.string "source_type", null: false, comment: "The type of source that resulted in this end product establishment."
    t.string "station", comment: "The station ID of the end product's station."
    t.string "synced_status", comment: "The status of the end product, which is synced by a job. Once and end product is cleared (CLR) or canceled (CAN) the status is final and the end product will not continue being synced."
    t.datetime "updated_at"
    t.integer "user_id", comment: "The ID of the user who performed the decision review intake."
    t.string "veteran_file_number", null: false, comment: "The file number of the Veteran submitted when establishing the end product."
    t.index ["source_type", "source_id"], name: "index_end_product_establishments_on_source_type_and_source_id"
    t.index ["updated_at"], name: "index_end_product_establishments_on_updated_at"
    t.index ["user_id"], name: "index_end_product_establishments_on_user_id"
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
    t.index ["updated_at"], name: "index_global_admin_logins_on_updated_at"
  end

  create_table "hearing_appeal_stream_snapshots", id: false, force: :cascade do |t|
    t.integer "appeal_id"
    t.datetime "created_at", null: false
    t.integer "hearing_id"
    t.datetime "updated_at"
    t.index ["hearing_id", "appeal_id"], name: "index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids", unique: true
    t.index ["updated_at"], name: "index_hearing_appeal_stream_snapshots_on_updated_at"
  end

  create_table "hearing_days", force: :cascade do |t|
    t.string "bva_poc"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false, comment: "The ID of the user who created the Hearing Day"
    t.datetime "deleted_at"
    t.integer "judge_id"
    t.boolean "lock"
    t.text "notes"
    t.string "regional_office"
    t.string "request_type", null: false
    t.string "room", comment: "The room at BVA where the hearing will take place"
    t.date "scheduled_for", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false, comment: "The ID of the user who most recently updated the Hearing Day"
    t.index ["created_by_id"], name: "index_hearing_days_on_created_by_id"
    t.index ["deleted_at"], name: "index_hearing_days_on_deleted_at"
    t.index ["updated_at"], name: "index_hearing_days_on_updated_at"
    t.index ["updated_by_id"], name: "index_hearing_days_on_updated_by_id"
  end

  create_table "hearing_issue_notes", force: :cascade do |t|
    t.boolean "allow", default: false
    t.datetime "created_at"
    t.boolean "deny", default: false
    t.boolean "dismiss", default: false
    t.bigint "hearing_id", null: false
    t.boolean "remand", default: false
    t.boolean "reopen", default: false
    t.bigint "request_issue_id", null: false
    t.datetime "updated_at"
    t.string "worksheet_notes"
    t.index ["hearing_id"], name: "index_hearing_issue_notes_on_hearing_id"
    t.index ["request_issue_id"], name: "index_hearing_issue_notes_on_request_issue_id"
    t.index ["updated_at"], name: "index_hearing_issue_notes_on_updated_at"
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
    t.index ["hearing_id"], name: "index_hearing_locations_on_hearing_id"
    t.index ["hearing_type"], name: "index_hearing_locations_on_hearing_type"
    t.index ["updated_at"], name: "index_hearing_locations_on_updated_at"
  end

  create_table "hearing_task_associations", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "hearing_id", null: false
    t.bigint "hearing_task_id", null: false
    t.string "hearing_type", null: false
    t.datetime "updated_at"
    t.index ["hearing_task_id"], name: "index_hearing_task_associations_on_hearing_task_id"
    t.index ["hearing_type", "hearing_id"], name: "index_hearing_task_associations_on_hearing_type_and_hearing_id"
    t.index ["updated_at"], name: "index_hearing_task_associations_on_updated_at"
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
    t.datetime "created_at", comment: "Automatic timestamp when row was created."
    t.bigint "created_by_id", comment: "The ID of the user who created the Hearing"
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
    t.datetime "updated_at", comment: "Timestamp when record was last updated."
    t.bigint "updated_by_id", comment: "The ID of the user who most recently updated the Hearing"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    t.string "witness"
    t.index ["created_by_id"], name: "index_hearings_on_created_by_id"
    t.index ["updated_at"], name: "index_hearings_on_updated_at"
    t.index ["updated_by_id"], name: "index_hearings_on_updated_by_id"
    t.index ["uuid"], name: "index_hearings_on_uuid"
  end

  create_table "higher_level_reviews", comment: "Intake data for Higher Level Reviews.", force: :cascade do |t|
    t.string "benefit_type", comment: "The benefit type selected by the Veteran on their form, also known as a Line of Business."
    t.datetime "created_at"
    t.datetime "establishment_attempted_at", comment: "Timestamp for the most recent attempt at establishing a claim."
    t.datetime "establishment_canceled_at", comment: "Timestamp when job was abandoned"
    t.string "establishment_error", comment: "The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds."
    t.datetime "establishment_last_submitted_at", comment: "Timestamp for the latest attempt at establishing the End Products for the Decision Review."
    t.datetime "establishment_processed_at", comment: "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing."
    t.datetime "establishment_submitted_at", comment: "Timestamp for when the Higher Level Review was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously."
    t.boolean "informal_conference", comment: "Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference. This creates a claimant letter and a tracked item in BGS."
    t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw their Higher Level Review request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it."
    t.date "receipt_date", comment: "The date that the Higher Level Review form was received by central mail. This is used to determine which issues are eligible to be appealed based on timeliness.  Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established."
    t.boolean "same_office", comment: "Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review."
    t.datetime "updated_at"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false, comment: "The universally unique identifier for the Higher Level Review. Can be used to link to the claim after it is completed."
    t.string "veteran_file_number", null: false, comment: "The file number of the Veteran that the Higher Level Review is for."
    t.boolean "veteran_is_not_claimant", comment: "Indicates whether the Veteran is the claimant on the Higher Level Review form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased."
    t.index ["updated_at"], name: "index_higher_level_reviews_on_updated_at"
    t.index ["uuid"], name: "index_higher_level_reviews_on_uuid"
    t.index ["veteran_file_number"], name: "index_higher_level_reviews_on_veteran_file_number"
  end

  create_table "intakes", id: :serial, comment: "Represents the intake of an form or request made by a veteran.", force: :cascade do |t|
    t.string "cancel_other", comment: "Notes added if a user canceled an intake for any reason other than the stock set of options."
    t.string "cancel_reason", comment: "The reason the intake was canceled. Could have been manually canceled by a user, or automatic."
    t.datetime "completed_at", comment: "Timestamp for when the intake was completed, whether it was successful or not."
    t.datetime "completion_started_at", comment: "Timestamp for when the user submitted the intake to be completed."
    t.string "completion_status", comment: "Indicates whether the intake was successful, or was closed by being canceled, expired, or due to an error."
    t.datetime "created_at"
    t.integer "detail_id", comment: "The ID of the record created as a result of the intake."
    t.string "detail_type", comment: "The type of the record created as a result of the intake."
    t.string "error_code", comment: "If the intake was unsuccessful due to a set of known errors, the error code is stored here. An error is also stored here for RAMP elections that are connected to an active end product, even though the intake is a success."
    t.datetime "started_at", comment: "Timestamp for when the intake was created, which happens when a user successfully searches for a Veteran."
    t.string "type", comment: "The class name of the intake."
    t.datetime "updated_at"
    t.integer "user_id", null: false, comment: "The ID of the user who created the intake."
    t.string "veteran_file_number", comment: "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    t.index ["type", "veteran_file_number"], name: "unique_index_to_avoid_duplicate_intakes", unique: true, where: "(completed_at IS NULL)"
    t.index ["type"], name: "index_intakes_on_type"
    t.index ["updated_at"], name: "index_intakes_on_updated_at"
    t.index ["user_id"], name: "index_intakes_on_user_id"
    t.index ["user_id"], name: "unique_index_to_avoid_multiple_intakes", unique: true, where: "(completed_at IS NULL)"
    t.index ["veteran_file_number"], name: "index_intakes_on_veteran_file_number"
  end

  create_table "job_notes", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at"
    t.bigint "job_id", null: false, comment: "The job to which the note applies"
    t.string "job_type", null: false
    t.text "note", null: false, comment: "The note"
    t.boolean "send_to_intake_user", default: false, comment: "Should the note trigger a message to the job intake user"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at"
    t.bigint "user_id", null: false, comment: "The user who created the note"
    t.index ["job_type", "job_id"], name: "index_job_notes_on_job_type_and_job_id"
    t.index ["updated_at"], name: "index_job_notes_on_updated_at"
    t.index ["user_id"], name: "index_job_notes_on_user_id"
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
    t.text "positive_feedback", default: [], array: true
    t.string "quality"
    t.string "task_id"
    t.datetime "updated_at", null: false
    t.index ["updated_at"], name: "index_judge_case_reviews_on_updated_at"
  end

  create_table "judge_team_roles", comment: "Defines roles for individual members of judge teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organizations_user_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["organizations_user_id"], name: "index_judge_team_roles_on_organizations_user_id", unique: true
    t.index ["updated_at"], name: "index_judge_team_roles_on_updated_at"
  end

  create_table "legacy_appeals", force: :cascade do |t|
    t.bigint "appeal_series_id"
    t.string "closest_regional_office"
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.datetime "created_at"
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
    t.datetime "updated_at"
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.string "vacols_id", null: false
    t.boolean "vamc", default: false
    t.string "vbms_id"
    t.boolean "vocational_rehab", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.index ["appeal_series_id"], name: "index_legacy_appeals_on_appeal_series_id"
    t.index ["updated_at"], name: "index_legacy_appeals_on_updated_at"
    t.index ["vacols_id"], name: "index_legacy_appeals_on_vacols_id", unique: true
  end

  create_table "legacy_hearings", force: :cascade do |t|
    t.integer "appeal_id"
    t.datetime "created_at", comment: "Automatic timestamp when row was created."
    t.bigint "created_by_id", comment: "The ID of the user who created the Legacy Hearing"
    t.bigint "hearing_day_id", comment: "The hearing day the hearing will take place on"
    t.string "military_service"
    t.boolean "prepped"
    t.text "summary"
    t.datetime "updated_at", comment: "Timestamp when record was last updated."
    t.bigint "updated_by_id", comment: "The ID of the user who most recently updated the Legacy Hearing"
    t.integer "user_id"
    t.string "vacols_id", null: false
    t.string "witness"
    t.index ["created_by_id"], name: "index_legacy_hearings_on_created_by_id"
    t.index ["hearing_day_id"], name: "index_legacy_hearings_on_hearing_day_id"
    t.index ["updated_at"], name: "index_legacy_hearings_on_updated_at"
    t.index ["updated_by_id"], name: "index_legacy_hearings_on_updated_by_id"
    t.index ["user_id"], name: "index_legacy_hearings_on_user_id"
    t.index ["vacols_id"], name: "index_legacy_hearings_on_vacols_id", unique: true
  end

  create_table "legacy_issue_optins", comment: "When a VACOLS issue from a legacy appeal is opted-in to AMA, this table keeps track of the related request_issue, and the status of processing the opt-in, or rollback if the request issue is removed from a Decision Review.", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "When a Request Issue is connected to a VACOLS issue on a legacy appeal, and the Veteran has agreed to withdraw their legacy appeals, a legacy_issue_optin is created at the time the Decision Review is successfully intaken. This is used to indicate that the legacy issue should subsequently be opted into AMA in VACOLS. "
    t.string "error"
    t.bigint "legacy_issue_id", comment: "The legacy issue being opted in, which connects to the request issue"
    t.datetime "optin_processed_at", comment: "The timestamp for when the opt-in was successfully processed, meaning it was updated in VACOLS as opted into AMA."
    t.string "original_disposition_code", comment: "The original disposition code of the VACOLS issue being opted in. Stored in case the opt-in is rolled back."
    t.date "original_disposition_date", comment: "The original disposition date of the VACOLS issue being opted in. Stored in case the opt-in is rolled back."
    t.bigint "request_issue_id", null: false, comment: "The request issue connected to the legacy VACOLS issue that has been opted in."
    t.datetime "rollback_created_at", comment: "Timestamp for when the connected request issue is removed from a Decision Review during edit, indicating that the opt-in needs to be rolled back."
    t.datetime "rollback_processed_at", comment: "Timestamp for when a rolled back opt-in has successfully finished being rolled back."
    t.datetime "updated_at", null: false, comment: "Automatically populated when the record is updated."
    t.index ["legacy_issue_id"], name: "index_legacy_issue_optins_on_legacy_issue_id"
    t.index ["request_issue_id"], name: "index_legacy_issue_optins_on_request_issue_id"
    t.index ["updated_at"], name: "index_legacy_issue_optins_on_updated_at"
  end

  create_table "legacy_issues", comment: "On an AMA decision review, when a veteran requests to review an issue that is already being contested on a legacy appeal, the legacy issue is connected to the request issue. If the veteran also chooses to opt their legacy issues into AMA and the issue is eligible to be transferred to AMA, the issues are closed in VACOLS through a legacy issue opt-in. This table stores the legacy issues connected to each request issue, and the record for opting them into AMA (if applicable).", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at"
    t.bigint "request_issue_id", null: false, comment: "The request issue the legacy issue is being connected to."
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at"
    t.string "vacols_id", null: false, comment: "The VACOLS ID of the legacy appeal that the legacy issue is part of."
    t.integer "vacols_sequence_id", null: false, comment: "The sequence ID of the legacy issue on the legacy appeal. The vacols_id and vacols_sequence_id form a composite key to identify a specific legacy issue."
    t.index ["request_issue_id"], name: "index_legacy_issues_on_request_issue_id"
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "detail_id", comment: "ID of the related object"
    t.string "detail_type", comment: "Model name of the related object"
    t.string "message_type", comment: "The type of event that caused this message to be created"
    t.datetime "read_at", comment: "When the message was read"
    t.string "text", comment: "The message"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false, comment: "The user for whom the message is intended"
    t.index ["detail_type", "detail_id"], name: "index_messages_on_detail_type_and_detail_id"
    t.index ["updated_at"], name: "index_messages_on_updated_at"
  end

  create_table "non_availabilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "object_identifier", null: false
    t.bigint "schedule_period_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_period_id"], name: "index_non_availabilities_on_schedule_period_id"
    t.index ["updated_at"], name: "index_non_availabilities_on_updated_at"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.string "participant_id", comment: "Organizations BGS partipant id"
    t.string "role", comment: "Role users in organization must have, if present"
    t.string "status", default: "active", comment: "Whether organization is active, inactive, or in some other Status."
    t.datetime "status_updated_at", comment: "Track when organization status last changed."
    t.string "type", comment: "Single table inheritance"
    t.datetime "updated_at"
    t.string "url", comment: "Unique portion of the organization queue url"
    t.index ["status"], name: "index_organizations_on_status"
    t.index ["updated_at"], name: "index_organizations_on_updated_at"
    t.index ["url"], name: "index_organizations_on_url", unique: true
  end

  create_table "organizations_users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at"
    t.integer "organization_id"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["updated_at"], name: "index_organizations_users_on_updated_at"
    t.index ["user_id", "organization_id"], name: "index_organizations_users_on_user_id_and_organization_id", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email_address", comment: "Person email address, cached from BGS"
    t.string "first_name", comment: "Person first name, cached from BGS"
    t.string "last_name", comment: "Person last name, cached from BGS"
    t.string "middle_name", comment: "Person middle name, cached from BGS"
    t.string "name_suffix", comment: "Person name suffix, cached from BGS"
    t.string "participant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_people_on_participant_id", unique: true
    t.index ["updated_at"], name: "index_people_on_updated_at"
  end

  create_table "post_decision_motions", comment: "Stores the disposition and associated task of post-decisional motions handled by the Litigation Support Team: Motion for Reconsideration, Motion to Vacate, and Clear and Unmistakeable Error.", force: :cascade do |t|
    t.bigint "appeal_id"
    t.datetime "created_at", null: false
    t.string "disposition", comment: "Possible options are Grant, Deny, Withdraw, and Dismiss"
    t.bigint "task_id"
    t.datetime "updated_at", null: false
    t.string "vacate_type", comment: "Granted motion to vacate can be Straight Vacate, Vacate and Readjudication, or Vacate and De Novo."
    t.integer "vacated_decision_issue_ids", comment: "When a motion to vacate is partially granted, this includes an array of the appeal's decision issue IDs that were chosen for vacatur in this post-decision motion. For full grant, this includes all prior decision issue IDs.", array: true
    t.index ["task_id"], name: "index_post_decision_motions_on_task_id"
    t.index ["updated_at"], name: "index_post_decision_motions_on_updated_at"
  end

  create_table "ramp_closed_appeals", id: :serial, comment: "Keeps track of legacy appeals that are closed or partially closed in VACOLS due to being transitioned to a RAMP election.  This data can be used to rollback the RAMP Election if needed.", force: :cascade do |t|
    t.datetime "closed_on", comment: "The datetime that the legacy appeal was closed in VACOLS and opted into RAMP."
    t.datetime "created_at"
    t.date "nod_date", comment: "The date when the Veteran filed a Notice of Disagreement for the original claims decision in the legacy system."
    t.string "partial_closure_issue_sequence_ids", comment: "If the entire legacy appeal could not be closed and moved to the RAMP Election, the VACOLS sequence IDs of issues on the legacy appeal which were closed are stored here, indicating that it was a partial closure.", array: true
    t.integer "ramp_election_id", comment: "The ID of the RAMP election that closed the legacy appeal."
    t.datetime "updated_at"
    t.string "vacols_id", null: false, comment: "The VACOLS BFKEY of the legacy appeal that has been closed and opted into RAMP."
    t.index ["updated_at"], name: "index_ramp_closed_appeals_on_updated_at"
  end

  create_table "ramp_election_rollbacks", comment: "If a RAMP election needs to get rolled back, for example if the EP is canceled, it is tracked here. Also any VACOLS issues that were closed in the legacy system and opted into RAMP are re-opened in the legacy system.", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "Timestamp for when the rollback was created."
    t.bigint "ramp_election_id", comment: "The ID of the RAMP Election being rolled back."
    t.string "reason", comment: "The reason for rolling back the RAMP Election. Rollbacks happen automatically for canceled RAMP Election End Products, but can also happen for other reason such as by request."
    t.string "reopened_vacols_ids", comment: "The IDs of any legacy appeals which were reopened as a result of rolling back the RAMP Election, corresponding to the VACOLS BFKEY.", array: true
    t.datetime "updated_at", null: false, comment: "Timestamp for when the rollback was last updated."
    t.bigint "user_id", comment: "The user who created the RAMP Election rollback, typically a system user."
    t.index ["ramp_election_id"], name: "index_ramp_election_rollbacks_on_ramp_election_id"
    t.index ["updated_at"], name: "index_ramp_election_rollbacks_on_updated_at"
    t.index ["user_id"], name: "index_ramp_election_rollbacks_on_user_id"
  end

  create_table "ramp_elections", id: :serial, comment: "Intake data for RAMP elections.", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "established_at", comment: "Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable."
    t.date "notice_date", comment: "The date that the Veteran was notified of their option to opt their legacy appeals into RAMP."
    t.string "option_selected", comment: "Indicates whether the Veteran selected for their RAMP election to be processed as a higher level review (with or without a hearing), a supplemental claim, or a board appeal."
    t.date "receipt_date", comment: "The date that the RAMP form was received by central mail."
    t.datetime "updated_at"
    t.string "veteran_file_number", null: false, comment: "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    t.index ["updated_at"], name: "index_ramp_elections_on_updated_at"
    t.index ["veteran_file_number"], name: "index_ramp_elections_on_veteran_file_number"
  end

  create_table "ramp_issues", id: :serial, comment: "Issues added to an end product as contentions for RAMP reviews. For RAMP elections, these are created in VBMS after the end product is established and updated in Caseflow when the end product is synced. For RAMP refilings, these are selected from the RAMP election's issues and added to the RAMP refiling end product that is established.", force: :cascade do |t|
    t.string "contention_reference_id", comment: "The ID of the contention created in VBMS that corresponds to the RAMP issue."
    t.datetime "created_at"
    t.string "description", null: false, comment: "The description of the contention in VBMS."
    t.integer "review_id", null: false, comment: "The ID of the RAMP election or RAMP refiling for this issue."
    t.string "review_type", null: false, comment: "The type of RAMP review the issue is on, indicating whether this is a RAMP election issue or a RAMP refiling issue."
    t.integer "source_issue_id", comment: "If a RAMP election issue added to a RAMP refiling, it is the source issue for the corresponding RAMP refiling issue."
    t.datetime "updated_at"
    t.index ["review_type", "review_id"], name: "index_ramp_issues_on_review_type_and_review_id"
    t.index ["updated_at"], name: "index_ramp_issues_on_updated_at"
  end

  create_table "ramp_refilings", id: :serial, comment: "Intake data for RAMP refilings, also known as RAMP selection.", force: :cascade do |t|
    t.string "appeal_docket", comment: "When the RAMP refiling option selected is appeal, they can select hearing, direct review or evidence submission as the appeal docket."
    t.datetime "created_at"
    t.datetime "established_at", comment: "Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable."
    t.datetime "establishment_processed_at", comment: "Timestamp for when the end product establishments for the RAMP review finished processing."
    t.datetime "establishment_submitted_at", comment: "Timestamp for when an intake for a review was submitted by the user."
    t.boolean "has_ineligible_issue", comment: "Selected by the user during intake, indicates whether the Veteran listed ineligible issues on their refiling."
    t.string "option_selected", comment: "Which lane the RAMP refiling is for, between appeal, higher level review, and supplemental claim."
    t.date "receipt_date", comment: "Receipt date of the RAMP form."
    t.datetime "updated_at"
    t.string "veteran_file_number", null: false, comment: "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    t.index ["updated_at"], name: "index_ramp_refilings_on_updated_at"
    t.index ["veteran_file_number"], name: "index_ramp_refilings_on_veteran_file_number"
  end

  create_table "record_synced_by_jobs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "error"
    t.datetime "processed_at"
    t.bigint "record_id"
    t.string "record_type"
    t.string "sync_job_name"
    t.datetime "updated_at"
    t.index ["record_type", "record_id"], name: "index_record_synced_by_jobs_on_record_type_and_record_id"
    t.index ["updated_at"], name: "index_record_synced_by_jobs_on_updated_at"
  end

  create_table "remand_reasons", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "decision_issue_id"
    t.boolean "post_aoj"
    t.datetime "updated_at", null: false
    t.index ["decision_issue_id"], name: "index_remand_reasons_on_decision_issue_id"
    t.index ["updated_at"], name: "index_remand_reasons_on_updated_at"
  end

  create_table "request_decision_issues", comment: "Join table for the has and belongs to many to many relationship between request issues and decision issues.", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "Automatic timestamp when row was created."
    t.integer "decision_issue_id", comment: "The ID of the decision issue."
    t.datetime "deleted_at"
    t.integer "request_issue_id", comment: "The ID of the request issue."
    t.datetime "updated_at", null: false, comment: "Automatically populated when the record is updated."
    t.index ["request_issue_id", "decision_issue_id"], name: "index_on_request_issue_id_and_decision_issue_id", unique: true
    t.index ["updated_at"], name: "index_request_decision_issues_on_updated_at"
  end

  create_table "request_issues", comment: "Each Request Issue represents the Veteran's response to a Rating Issue. Request Issues come in three flavors: rating, nonrating, and unidentified. They are attached to a Decision Review and (for those that track contentions) an End Product Establishment. A Request Issue can contest a rating issue, a decision issue, or a nonrating issue without a decision issue.", force: :cascade do |t|
    t.string "benefit_type", null: false, comment: "The Line of Business the issue is connected with."
    t.datetime "closed_at", comment: "Timestamp when the request issue was closed. The reason it was closed is in closed_status."
    t.string "closed_status", comment: "Indicates whether the request issue is closed, for example if it was removed from a Decision Review, the associated End Product got canceled, the Decision Review was withdrawn."
    t.integer "contention_reference_id", comment: "The ID of the contention created on the End Product for this request issue. This is populated after the contention is created in VBMS."
    t.datetime "contention_removed_at", comment: "When a request issue is removed from a Decision Review during an edit, if it has a contention in VBMS that is also removed. This field indicates when the contention has successfully been removed in VBMS."
    t.datetime "contention_updated_at", comment: "Timestamp indicating when a contention was successfully updated in VBMS."
    t.integer "contested_decision_issue_id", comment: "The ID of the decision issue that this request issue contests. A Request issue will contest either a rating issue or a decision issue"
    t.string "contested_issue_description", comment: "Description of the contested rating or decision issue. Will be either a rating issue's decision text or a decision issue's description."
    t.string "contested_rating_decision_reference_id", comment: "The BGS id for contested rating decisions. These may not have corresponding contested_rating_issue_reference_id values."
    t.string "contested_rating_issue_diagnostic_code", comment: "If the contested issue is a rating issue, this is the rating issue's diagnostic code. Will be nil if this request issue contests a decision issue."
    t.string "contested_rating_issue_profile_date", comment: "If the contested issue is a rating issue, this is the rating issue's profile date. Will be nil if this request issue contests a decision issue."
    t.string "contested_rating_issue_reference_id", comment: "If the contested issue is a rating issue, this is the rating issue's reference id. Will be nil if this request issue contests a decision issue."
    t.integer "corrected_by_request_issue_id", comment: "If this request issue has been corrected, the ID of the new correction request issue. This is needed for EP 930."
    t.string "correction_type", comment: "EP 930 correction type. Allowed values: control, local_quality_error, national_quality_error where 'control' is a regular correction, 'local_quality_error' was found after the fact by a local quality review team, and 'national_quality_error' was similarly found by a national quality review team. This is needed for EP 930."
    t.boolean "covid_timeliness_exempt", comment: "If a veteran requests a timeliness exemption that is related to COVID-19, this is captured when adding a Request Issue and available for reporting."
    t.datetime "created_at", comment: "Automatic timestamp when row was created"
    t.date "decision_date", comment: "Either the rating issue's promulgation date, the decision issue's approx decision date or the decision date entered by the user (for nonrating and unidentified issues)"
    t.bigint "decision_review_id", comment: "ID of the decision review that this request issue belongs to"
    t.string "decision_review_type", comment: "Class name of the decision review that this request issue belongs to"
    t.datetime "decision_sync_attempted_at", comment: "Async job processing last attempted timestamp"
    t.datetime "decision_sync_canceled_at", comment: "Timestamp when job was abandoned"
    t.string "decision_sync_error", comment: "Async job processing last error message"
    t.datetime "decision_sync_last_submitted_at", comment: "Async job processing most recent start timestamp"
    t.datetime "decision_sync_processed_at", comment: "Async job processing completed timestamp"
    t.datetime "decision_sync_submitted_at", comment: "Async job processing start timestamp"
    t.string "edited_description", comment: "The edited description for the contested issue, optionally entered by the user."
    t.integer "end_product_establishment_id", comment: "The ID of the End Product Establishment created for this request issue."
    t.bigint "ineligible_due_to_id", comment: "If a request issue is ineligible due to another request issue, for example that issue is already being actively reviewed, then the ID of the other request issue is stored here."
    t.string "ineligible_reason", comment: "The reason for a Request Issue being ineligible. If a Request Issue has an ineligible_reason, it is still captured, but it will not get a contention in VBMS or a decision."
    t.boolean "is_unidentified", comment: "Indicates whether a Request Issue is unidentified, meaning it wasn't found in the list of contestable issues, and is not a new nonrating issue. Contentions for unidentified issues are created on a rating End Product if processed in VBMS but without the issue description, and someone is required to edit it in Caseflow before proceeding with the decision."
    t.string "nonrating_issue_category", comment: "The category selected for nonrating request issues. These vary by business line."
    t.string "nonrating_issue_description", comment: "The user entered description if the issue is a nonrating issue"
    t.text "notes", comment: "Notes added by the Claims Assistant when adding request issues. This may be used to capture handwritten notes on the form, or other comments the CA wants to capture."
    t.string "ramp_claim_id", comment: "If a rating issue was created as a result of an issue intaken for a RAMP Review, it will be connected to the former RAMP issue by its End Product's claim ID."
    t.datetime "rating_issue_associated_at", comment: "Timestamp when a contention and its contested rating issue are associated in VBMS."
    t.string "unidentified_issue_text", comment: "User entered description if the request issue is neither a rating or a nonrating issue"
    t.boolean "untimely_exemption", comment: "If the contested issue's decision date was more than a year before the receipt date, it is considered untimely (unless it is a Supplemental Claim). However, an exemption to the timeliness can be requested. If so, it is indicated here."
    t.text "untimely_exemption_notes", comment: "Notes related to the untimeliness exemption requested."
    t.datetime "updated_at", comment: "Automatic timestamp whenever the record changes."
    t.string "vacols_id", comment: "The vacols_id of the legacy appeal that had an issue found to match the request issue."
    t.integer "vacols_sequence_id", comment: "The vacols_sequence_id, for the specific issue on the legacy appeal which the Claims Assistant determined to match the request issue on the Decision Review. A combination of the vacols_id (for the legacy appeal), and vacols_sequence_id (for which issue on the legacy appeal), is required to identify the issue being opted-in."
    t.boolean "verified_unidentified_issue", comment: "A verified unidentified issue allows an issue whose rating data is missing to be intaken as a regular rating issue. In order to be marked as verified, a VSR needs to confirm that they were able to find the record of the decision for the issue."
    t.string "veteran_participant_id", comment: "The veteran participant ID. This should be unique in upstream systems and used in the future to reconcile duplicates."
    t.index ["closed_at"], name: "index_request_issues_on_closed_at"
    t.index ["contention_reference_id"], name: "index_request_issues_on_contention_reference_id", unique: true
    t.index ["contested_decision_issue_id"], name: "index_request_issues_on_contested_decision_issue_id"
    t.index ["contested_rating_decision_reference_id"], name: "index_request_issues_on_contested_rating_decision_reference_id"
    t.index ["contested_rating_issue_reference_id"], name: "index_request_issues_on_contested_rating_issue_reference_id"
    t.index ["decision_review_type", "decision_review_id"], name: "index_request_issues_on_decision_review_columns"
    t.index ["end_product_establishment_id"], name: "index_request_issues_on_end_product_establishment_id"
    t.index ["ineligible_due_to_id"], name: "index_request_issues_on_ineligible_due_to_id"
    t.index ["ineligible_reason"], name: "index_request_issues_on_ineligible_reason"
    t.index ["updated_at"], name: "index_request_issues_on_updated_at"
  end

  create_table "request_issues_updates", comment: "Keeps track of edits to request issues on a decision review that happen after the initial intake, such as removing and adding issues.  When the decision review is processed in VBMS, this also tracks whether adding or removing contentions in VBMS for the update has succeeded.", force: :cascade do |t|
    t.integer "after_request_issue_ids", null: false, comment: "An array of the active request issue IDs after a user has finished editing a decision review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added).", array: true
    t.datetime "attempted_at", comment: "Timestamp for when the request issue update processing was last attempted."
    t.integer "before_request_issue_ids", null: false, comment: "An array of the active request issue IDs previously on the decision review before this editing session. Used with after_request_issue_ids to determine appropriate actions (such as which contentions need to be removed).", array: true
    t.datetime "canceled_at", comment: "Timestamp when job was abandoned"
    t.integer "corrected_request_issue_ids", comment: "An array of the request issue IDs that were corrected during this request issues update.", array: true
    t.datetime "created_at", comment: "Timestamp when record was initially created"
    t.integer "edited_request_issue_ids", comment: "An array of the request issue IDs that were edited during this request issues update", array: true
    t.string "error", comment: "The error message if the last attempt at processing the request issues update was not successful."
    t.datetime "last_submitted_at", comment: "Timestamp for when the processing for the request issues update was last submitted. Used to determine how long to continue retrying the processing job. Can be reset to allow for additional retries."
    t.datetime "processed_at", comment: "Timestamp for when the request issue update successfully completed processing."
    t.bigint "review_id", null: false, comment: "The ID of the decision review edited."
    t.string "review_type", null: false, comment: "The type of the decision review edited."
    t.datetime "submitted_at", comment: "Timestamp when the request issues update was originally submitted."
    t.datetime "updated_at", comment: "Timestamp when record was last updated."
    t.bigint "user_id", null: false, comment: "The ID of the user who edited the decision review."
    t.integer "withdrawn_request_issue_ids", comment: "An array of the request issue IDs that were withdrawn during this request issues update.", array: true
    t.index ["review_type", "review_id"], name: "index_request_issues_updates_on_review_type_and_review_id"
    t.index ["updated_at"], name: "index_request_issues_updates_on_updated_at"
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
    t.index ["updated_at"], name: "index_schedule_periods_on_updated_at"
    t.index ["user_id"], name: "index_schedule_periods_on_user_id"
  end

  create_table "special_issue_lists", force: :cascade do |t|
    t.bigint "appeal_id"
    t.string "appeal_type"
    t.boolean "contaminated_water_at_camp_lejeune", default: false
    t.datetime "created_at"
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
    t.datetime "updated_at"
    t.boolean "us_territory_claim_american_samoa_guam_northern_mariana_isla", default: false
    t.boolean "us_territory_claim_philippines", default: false
    t.boolean "us_territory_claim_puerto_rico_and_virgin_islands", default: false
    t.boolean "vamc", default: false
    t.boolean "vocational_rehab", default: false
    t.boolean "waiver_of_overpayment", default: false
    t.index ["appeal_type", "appeal_id"], name: "index_special_issue_lists_on_appeal_type_and_appeal_id"
    t.index ["updated_at"], name: "index_special_issue_lists_on_updated_at"
  end

  create_table "supplemental_claims", comment: "Intake data for Supplemental Claims.", force: :cascade do |t|
    t.string "benefit_type", comment: "The benefit type selected by the Veteran on their form, also known as a Line of Business."
    t.datetime "created_at"
    t.bigint "decision_review_remanded_id", comment: "If an Appeal or Higher Level Review decision is remanded, including Duty to Assist errors, it automatically generates a new Supplemental Claim.  If this Supplemental Claim was generated, then the ID of the original Decision Review with the remanded decision is stored here."
    t.string "decision_review_remanded_type", comment: "The type of the Decision Review remanded if applicable, used with decision_review_remanded_id to as a composite key to identify the remanded Decision Review."
    t.datetime "establishment_attempted_at", comment: "Timestamp for the most recent attempt at establishing a claim."
    t.datetime "establishment_canceled_at", comment: "Timestamp when job was abandoned"
    t.string "establishment_error", comment: "The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds."
    t.datetime "establishment_last_submitted_at", comment: "Timestamp for the latest attempt at establishing the End Products for the Decision Review."
    t.datetime "establishment_processed_at", comment: "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing."
    t.datetime "establishment_submitted_at", comment: "Timestamp for when the Supplemental Claim was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously."
    t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw their Supplemental Claim request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it."
    t.date "receipt_date", comment: "The date that the Supplemental Claim form was received by central mail. Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established. Supplemental Claims do not have the same timeliness restriction on contestable issues as Appeals and Higher Level Reviews."
    t.datetime "updated_at"
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false, comment: "The universally unique identifier for the Supplemental Claim. Can be used to link to the claim after it is completed."
    t.string "veteran_file_number", null: false, comment: "The file number of the Veteran that the Supplemental Claim is for."
    t.boolean "veteran_is_not_claimant", comment: "Indicates whether the Veteran is the claimant on the Supplemental Claim form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased."
    t.index ["decision_review_remanded_type", "decision_review_remanded_id"], name: "index_decision_issues_on_decision_review_remanded"
    t.index ["updated_at"], name: "index_supplemental_claims_on_updated_at"
    t.index ["uuid"], name: "index_supplemental_claims_on_uuid"
    t.index ["veteran_file_number"], name: "index_supplemental_claims_on_veteran_file_number"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["text"], name: "index_tags_on_text", unique: true
    t.index ["updated_at"], name: "index_tags_on_updated_at"
  end

  create_table "task_timers", comment: "Task timers allow tasks to be run asynchronously after some future date, like EvidenceSubmissionWindowTask.", force: :cascade do |t|
    t.datetime "attempted_at", comment: "Async timestamp for most recent attempt to run."
    t.datetime "canceled_at", comment: "Timestamp when job was abandoned"
    t.datetime "created_at", null: false, comment: "Automatic timestamp for record creation."
    t.string "error", comment: "Async any error message from most recent failed attempt to run."
    t.datetime "last_submitted_at", comment: "Async timestamp for most recent job start."
    t.datetime "processed_at", comment: "Async timestamp for when the job completes successfully."
    t.datetime "submitted_at", comment: "Async timestamp for initial job start."
    t.bigint "task_id", null: false, comment: "ID of the Task to be run."
    t.datetime "updated_at", null: false, comment: "Automatic timestmap for record update."
    t.index ["task_id"], name: "index_task_timers_on_task_id"
    t.index ["updated_at"], name: "index_task_timers_on_updated_at"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "appeal_id", null: false
    t.string "appeal_type", null: false
    t.datetime "assigned_at"
    t.integer "assigned_by_id"
    t.integer "assigned_to_id", null: false
    t.string "assigned_to_type", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "instructions", default: [], array: true
    t.integer "parent_id"
    t.datetime "placed_on_hold_at"
    t.datetime "started_at"
    t.string "status", default: "assigned"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["appeal_type", "appeal_id"], name: "index_tasks_on_appeal_type_and_appeal_id"
    t.index ["assigned_to_type", "assigned_to_id"], name: "index_tasks_on_assigned_to_type_and_assigned_to_id"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["type"], name: "index_tasks_on_type"
    t.index ["updated_at"], name: "index_tasks_on_updated_at"
  end

  create_table "team_quotas", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_count"
    t.index ["date", "task_type"], name: "index_team_quotas_on_date_and_task_type", unique: true
    t.index ["updated_at"], name: "index_team_quotas_on_updated_at"
  end

  create_table "transcriptions", force: :cascade do |t|
    t.datetime "created_at"
    t.date "expected_return_date"
    t.bigint "hearing_id"
    t.date "problem_notice_sent_date"
    t.string "problem_type"
    t.string "requested_remedy"
    t.date "sent_to_transcriber_date"
    t.string "task_number"
    t.string "transcriber"
    t.datetime "updated_at"
    t.date "uploaded_to_vbms_date"
    t.index ["hearing_id"], name: "index_transcriptions_on_hearing_id"
    t.index ["updated_at"], name: "index_transcriptions_on_updated_at"
  end

  create_table "user_quotas", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "locked_task_count"
    t.integer "team_quota_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["team_quota_id", "user_id"], name: "index_user_quotas_on_team_quota_id_and_user_id", unique: true
    t.index ["updated_at"], name: "index_user_quotas_on_updated_at"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "css_id", null: false
    t.datetime "efolder_documents_fetched_at", comment: "Date when efolder documents were cached in s3 for this user"
    t.string "email"
    t.string "full_name"
    t.datetime "last_login_at"
    t.string "roles", array: true
    t.string "selected_regional_office"
    t.string "station_id", null: false
    t.string "status", default: "active", comment: "Whether or not the user is an active user of caseflow"
    t.datetime "status_updated_at", comment: "When the user's status was last updated"
    t.datetime "updated_at"
    t.index "upper((css_id)::text)", name: "index_users_unique_css_id", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["updated_at"], name: "index_users_on_updated_at"
  end

  create_table "vbms_uploaded_documents", force: :cascade do |t|
    t.bigint "appeal_id", null: false
    t.datetime "attempted_at"
    t.datetime "canceled_at", comment: "Timestamp when job was abandoned"
    t.datetime "created_at", null: false
    t.string "document_type", null: false
    t.string "error"
    t.datetime "last_submitted_at"
    t.datetime "processed_at"
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.datetime "uploaded_to_vbms_at"
    t.index ["appeal_id"], name: "index_vbms_uploaded_documents_on_appeal_id"
    t.index ["updated_at"], name: "index_vbms_uploaded_documents_on_updated_at"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.uuid "request_id", comment: "The unique id of the request that caused this change"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["request_id"], name: "index_versions_on_request_id"
  end

  create_table "veterans", force: :cascade do |t|
    t.string "closest_regional_office"
    t.datetime "created_at"
    t.string "file_number", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "name_suffix"
    t.string "participant_id"
    t.string "ssn", comment: "The cached Social Security Number"
    t.datetime "updated_at"
    t.index ["file_number"], name: "index_veterans_on_file_number", unique: true
    t.index ["participant_id"], name: "index_veterans_on_participant_id"
    t.index ["ssn"], name: "index_veterans_on_ssn"
    t.index ["updated_at"], name: "index_veterans_on_updated_at"
  end

  create_table "virtual_hearing_establishments", force: :cascade do |t|
    t.datetime "attempted_at", comment: "Async timestamp for most recent attempt to run."
    t.datetime "canceled_at", comment: "Timestamp when job was abandoned."
    t.datetime "created_at", null: false, comment: "Automatic timestamp when row was created."
    t.string "error", comment: "Async any error message from most recent failed attempt to run."
    t.datetime "last_submitted_at", comment: "Async timestamp for most recent job start."
    t.datetime "processed_at", comment: "Timestamp for when the virtual hearing was successfully processed."
    t.datetime "submitted_at", comment: "Async timestamp for initial job start."
    t.datetime "updated_at", null: false, comment: "Timestamp when record was last updated."
    t.bigint "virtual_hearing_id", null: false, comment: "Virtual Hearing the conference is being established for."
    t.index ["virtual_hearing_id"], name: "index_virtual_hearing_establishments_on_virtual_hearing_id"
  end

  create_table "virtual_hearings", force: :cascade do |t|
    t.string "alias", comment: "Alias for conference in Pexip"
    t.boolean "conference_deleted", default: false, null: false, comment: "Whether or not the conference was deleted from Pexip"
    t.integer "conference_id", comment: "ID of conference from Pexip"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false, comment: "User who created the virtual hearing"
    t.integer "guest_pin", comment: "PIN number for guests of Pexip conference"
    t.bigint "hearing_id", comment: "Associated hearing"
    t.string "hearing_type"
    t.integer "host_pin", comment: "PIN number for host of Pexip conference"
    t.string "judge_email", comment: "Judge's email address"
    t.boolean "judge_email_sent", default: false, null: false, comment: "Whether or not a notification email was sent to the judge"
    t.string "representative_email", comment: "Veteran's representative's email address"
    t.boolean "representative_email_sent", default: false, null: false, comment: "Whether or not a notification email was sent to the veteran's representative"
    t.string "status", default: "pending", null: false, comment: "The status of the Pexip conference"
    t.datetime "updated_at", null: false
    t.string "veteran_email", comment: "Veteran's email address"
    t.boolean "veteran_email_sent", default: false, null: false, comment: "Whether or not a notification email was sent to the veteran"
    t.index ["alias"], name: "index_virtual_hearings_on_alias"
    t.index ["conference_id"], name: "index_virtual_hearings_on_conference_id"
    t.index ["created_by_id"], name: "index_virtual_hearings_on_created_by_id"
    t.index ["hearing_type", "hearing_id"], name: "index_virtual_hearings_on_hearing_type_and_hearing_id"
    t.index ["updated_at"], name: "index_virtual_hearings_on_updated_at"
  end

  create_table "vso_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ihp_dockets", array: true
    t.integer "organization_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_vso_configs_on_organization_id"
    t.index ["updated_at"], name: "index_vso_configs_on_updated_at"
  end

  create_table "worksheet_issues", id: :serial, force: :cascade do |t|
    t.boolean "allow", default: false
    t.integer "appeal_id"
    t.datetime "created_at"
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
    t.datetime "updated_at"
    t.string "vacols_sequence_id"
    t.index ["appeal_id"], name: "index_worksheet_issues_on_appeal_id"
    t.index ["deleted_at"], name: "index_worksheet_issues_on_deleted_at"
    t.index ["updated_at"], name: "index_worksheet_issues_on_updated_at"
  end

  add_foreign_key "advance_on_docket_motions", "users"
  add_foreign_key "annotations", "users"
  add_foreign_key "api_views", "api_keys"
  add_foreign_key "appeal_views", "users"
  add_foreign_key "certifications", "users"
  add_foreign_key "claims_folder_searches", "users"
  add_foreign_key "dispatch_tasks", "users"
  add_foreign_key "document_views", "users"
  add_foreign_key "end_product_establishments", "users"
  add_foreign_key "hearing_days", "users", column: "created_by_id"
  add_foreign_key "hearing_days", "users", column: "updated_by_id"
  add_foreign_key "hearing_views", "users"
  add_foreign_key "hearings", "users", column: "created_by_id"
  add_foreign_key "hearings", "users", column: "updated_by_id"
  add_foreign_key "intakes", "users"
  add_foreign_key "legacy_appeals", "appeal_series"
  add_foreign_key "legacy_hearings", "hearing_days"
  add_foreign_key "legacy_hearings", "users"
  add_foreign_key "legacy_hearings", "users", column: "created_by_id"
  add_foreign_key "legacy_hearings", "users", column: "updated_by_id"
  add_foreign_key "legacy_issue_optins", "legacy_issues"
  add_foreign_key "organizations_users", "users"
  add_foreign_key "post_decision_motions", "appeals"
  add_foreign_key "post_decision_motions", "tasks"
  add_foreign_key "ramp_closed_appeals", "ramp_elections"
  add_foreign_key "ramp_election_rollbacks", "users"
  add_foreign_key "request_issues_updates", "users"
  add_foreign_key "schedule_periods", "users"
  add_foreign_key "user_quotas", "users"
end
