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

ActiveRecord::Schema.define(version: 2020_02_12_205344) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appeals", comment: "Denormalized BVA NODs", force: :cascade do |t|
    t.boolean "active_appeal", null: false, comment: "Calculated based on BVA status"
    t.boolean "aod_due_to_dob", default: false, comment: "Calculated every day based on Claimant DOB"
    t.boolean "aod_granted", default: false, null: false, comment: "advance_on_docket_motions.granted"
    t.string "aod_reason", limit: 50, comment: "advance_on_docket_motions.reason"
    t.bigint "aod_user_id", comment: "advance_on_docket_motions.user_id"
    t.datetime "appeal_created_at", null: false, comment: "appeals.created_at"
    t.bigint "appeal_id", null: false, comment: "ID of the Appeal"
    t.datetime "appeal_updated_at", null: false, comment: "appeals.updated_at"
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
    t.datetime "created_at", null: false, comment: "Creation timestamp for the ETL record"
    t.integer "decision_status_sort_key", null: false, comment: "Integer for sorting status in display order"
    t.string "docket_number", limit: 50, null: false, comment: "Docket number"
    t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
    t.string "docket_type", limit: 50, null: false, comment: "Docket type"
    t.datetime "established_at", null: false, comment: "Timestamp for when the appeal was intaken successfully"
    t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
    t.string "poa_participant_id", limit: 20, comment: "Used to identify the power of attorney (POA)"
    t.date "receipt_date", null: false, comment: "Receipt date of the NOD form"
    t.string "status", limit: 32, null: false, comment: "Calculated BVA status based on Tasks"
    t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
    t.datetime "updated_at", null: false, comment: "Updated timestamp for the ETL record"
    t.uuid "uuid", null: false, comment: "The universally unique identifier for the appeal"
    t.date "veteran_dob", comment: "people.date_of_birth"
    t.string "veteran_file_number", limit: 20, null: false, comment: "Veteran file number"
    t.string "veteran_first_name", comment: "veterans.first_name"
    t.bigint "veteran_id", null: false, comment: "veterans.id"
    t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
    t.string "veteran_last_name", comment: "veterans.last_name"
    t.string "veteran_middle_name", comment: "veterans.middle_name"
    t.string "veteran_name_suffix", comment: "veterans.name_suffix"
    t.string "veteran_participant_id", limit: 20, comment: "veterans.participant_id"
    t.index ["active_appeal"], name: "index_appeals_on_active_appeal"
    t.index ["aod_due_to_dob"], name: "index_appeals_on_aod_due_to_dob"
    t.index ["aod_granted"], name: "index_appeals_on_aod_granted"
    t.index ["aod_user_id"], name: "index_appeals_on_aod_user_id"
    t.index ["appeal_created_at"], name: "index_appeals_on_appeal_created_at"
    t.index ["appeal_id"], name: "index_appeals_on_appeal_id"
    t.index ["appeal_updated_at"], name: "index_appeals_on_appeal_updated_at"
    t.index ["claimant_dob"], name: "index_appeals_on_claimant_dob"
    t.index ["claimant_id"], name: "index_appeals_on_claimant_id"
    t.index ["claimant_participant_id"], name: "index_appeals_on_claimant_participant_id"
    t.index ["claimant_person_id"], name: "index_appeals_on_claimant_person_id"
    t.index ["created_at"], name: "index_appeals_on_created_at"
    t.index ["decision_status_sort_key"], name: "index_appeals_on_decision_status_sort_key"
    t.index ["docket_type"], name: "index_appeals_on_docket_type"
    t.index ["poa_participant_id"], name: "index_appeals_on_poa_participant_id"
    t.index ["receipt_date"], name: "index_appeals_on_receipt_date"
    t.index ["status"], name: "index_appeals_on_status"
    t.index ["updated_at"], name: "index_appeals_on_updated_at"
    t.index ["uuid"], name: "index_appeals_on_uuid"
    t.index ["veteran_file_number"], name: "index_appeals_on_veteran_file_number"
    t.index ["veteran_id"], name: "index_appeals_on_veteran_id"
    t.index ["veteran_is_not_claimant"], name: "index_appeals_on_veteran_is_not_claimant"
    t.index ["veteran_participant_id"], name: "index_appeals_on_veteran_participant_id"
  end

  create_table "attorney_case_reviews", comment: "Denormalized attorney_case_reviews", force: :cascade do |t|
    t.bigint "appeal_id", null: false, comment: "tasks.appeal_id"
    t.string "appeal_type", null: false, comment: "tasks.appeal_type"
    t.string "attorney_css_id", limit: 20, null: false, comment: "users.css_id"
    t.string "attorney_full_name", limit: 255, null: false, comment: "users.full_name"
    t.bigint "attorney_id", null: false, comment: "attorney_case_reviews.attorney_id"
    t.string "attorney_sattyid", limit: 20, comment: "users.sattyid"
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.string "document_reference_id", limit: 50, comment: "attorney_case_reviews.document_id"
    t.string "document_type", limit: 20, comment: "attorney_case_reviews.document_type"
    t.text "note", comment: "attorney_case_reviews.note"
    t.boolean "overtime", comment: "attorney_case_reviews.overtime"
    t.datetime "review_created_at", null: false, comment: "attorney_case_reviews.created_at"
    t.bigint "review_id", null: false, comment: "attorney_case_reviews.id"
    t.datetime "review_updated_at", null: false, comment: "attorney_case_reviews.updated_at"
    t.string "reviewing_judge_css_id", limit: 20, null: false, comment: "users.css_id"
    t.string "reviewing_judge_full_name", limit: 255, null: false, comment: "users.full_name"
    t.bigint "reviewing_judge_id", null: false, comment: "attorney_case_reviews.reviewing_judge_id"
    t.string "reviewing_judge_sattyid", limit: 20, comment: "users.sattyid"
    t.string "task_id", null: false, comment: "attorney_case_reviews.task_id"
    t.boolean "untimely_evidence", comment: "attorney_case_reviews.untimely_evidence"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.string "vacols_id", comment: "Substring attorney_case_reviews.task_id for Legacy Appeals"
    t.string "work_product", limit: 20, comment: "attorney_case_reviews.work_product"
    t.index ["appeal_id"], name: "index_attorney_case_reviews_on_appeal_id"
    t.index ["appeal_type"], name: "index_attorney_case_reviews_on_appeal_type"
    t.index ["attorney_id"], name: "index_attorney_case_reviews_on_attorney_id"
    t.index ["created_at"], name: "index_attorney_case_reviews_on_created_at"
    t.index ["document_type"], name: "index_attorney_case_reviews_on_document_type"
    t.index ["review_created_at"], name: "index_attorney_case_reviews_on_review_created_at"
    t.index ["review_id"], name: "index_attorney_case_reviews_on_review_id"
    t.index ["review_updated_at"], name: "index_attorney_case_reviews_on_review_updated_at"
    t.index ["reviewing_judge_id"], name: "index_attorney_case_reviews_on_reviewing_judge_id"
    t.index ["task_id"], name: "index_attorney_case_reviews_on_task_id"
    t.index ["updated_at"], name: "index_attorney_case_reviews_on_updated_at"
    t.index ["vacols_id"], name: "index_attorney_case_reviews_on_vacols_id"
  end

  create_table "decision_issues", comment: "Copy of decision_issues", force: :cascade do |t|
    t.string "benefit_type", limit: 20, comment: "decision_issues.benefit_type"
    t.date "caseflow_decision_date", comment: "decision_issues.caseflow_decision_date"
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.bigint "decision_review_id", comment: "decision_issues.decision_review_id"
    t.string "decision_review_type", limit: 20, comment: "decision_issues.decision_review_type"
    t.string "decision_text", comment: "decision_issues.decision_text"
    t.string "description", comment: "decision_issues.description"
    t.string "diagnostic_code", limit: 20, comment: "decision_issues.diagnostic_code"
    t.string "disposition", limit: 50, comment: "decision_issues.disposition"
    t.date "end_product_last_action_date", comment: "decision_issues.end_product_last_action_date"
    t.datetime "issue_created_at", comment: "decision_issues.created_at"
    t.datetime "issue_deleted_at", comment: "decision_issues.deleted_at"
    t.datetime "issue_updated_at", comment: "decision_issues.updated_at"
    t.bigint "participant_id", null: false, comment: "decision_issues.participant_id"
    t.bigint "rating_issue_reference_id", comment: "decision_issues.rating_issue_reference_id"
    t.datetime "rating_profile_date", comment: "decision_issues.rating_profile_date"
    t.datetime "rating_promulgation_date", comment: "decision_issues.rating_promulgation_date"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.index ["created_at"], name: "index_decision_issues_on_created_at"
    t.index ["decision_review_id", "decision_review_type"], name: "index_decision_issues_decision_review"
    t.index ["disposition"], name: "index_decision_issues_on_disposition"
    t.index ["issue_created_at"], name: "index_decision_issues_on_issue_created_at"
    t.index ["issue_deleted_at"], name: "index_decision_issues_on_issue_deleted_at"
    t.index ["issue_updated_at"], name: "index_decision_issues_on_issue_updated_at"
    t.index ["participant_id"], name: "index_decision_issues_on_participant_id"
    t.index ["rating_issue_reference_id", "disposition", "participant_id"], name: "index_decision_issues_uniq", unique: true
    t.index ["updated_at"], name: "index_decision_issues_on_updated_at"
  end

  create_table "etl_build_tables", comment: "ETL table metadata, one for each table per-build", force: :cascade do |t|
    t.string "comments", comment: "Ad hoc comments (e.g. error message)"
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.bigint "etl_build_id", null: false, comment: "PK of the etl_build"
    t.datetime "finished_at", comment: "Build end time"
    t.bigint "rows_deleted", comment: "Number of rows deleted"
    t.bigint "rows_inserted", comment: "Number of new rows"
    t.bigint "rows_rejected", comment: "Number of rows skipped"
    t.bigint "rows_updated", comment: "Number of rows changed"
    t.datetime "started_at", comment: "Build start time (usually identical to created_at)"
    t.string "status", comment: "Enum value: running, complete, error"
    t.string "table_name", comment: "Name of the ETL table"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.index ["created_at"], name: "index_etl_build_tables_on_created_at"
    t.index ["etl_build_id"], name: "index_etl_build_tables_on_etl_build_id"
    t.index ["finished_at"], name: "index_etl_build_tables_on_finished_at"
    t.index ["started_at"], name: "index_etl_build_tables_on_started_at"
    t.index ["status"], name: "index_etl_build_tables_on_status"
    t.index ["table_name"], name: "index_etl_build_tables_on_table_name"
    t.index ["updated_at"], name: "index_etl_build_tables_on_updated_at"
  end

  create_table "etl_builds", comment: "ETL build metadata for each job", force: :cascade do |t|
    t.string "comments", comment: "Ad hoc comments (e.g. error message)"
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.datetime "finished_at", comment: "Build end time"
    t.datetime "started_at", comment: "Build start time (usually identical to created_at)"
    t.string "status", comment: "Enum value: running, complete, error"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.index ["created_at"], name: "index_etl_builds_on_created_at"
    t.index ["finished_at"], name: "index_etl_builds_on_finished_at"
    t.index ["started_at"], name: "index_etl_builds_on_started_at"
    t.index ["status"], name: "index_etl_builds_on_status"
    t.index ["updated_at"], name: "index_etl_builds_on_updated_at"
  end

  create_table "organizations", comment: "Copy of Organizations table", force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.string "participant_id", comment: "Organizations BGS partipant id"
    t.string "role", comment: "Role users in organization must have, if present"
    t.string "status", default: "active", comment: "Whether organization is active, inactive, or in some other Status."
    t.datetime "status_updated_at", comment: "Track when organization status last changed."
    t.string "type", comment: "Single table inheritance"
    t.datetime "updated_at"
    t.string "url", comment: "Unique portion of the organization queue url"
    t.index ["created_at"], name: "index_organizations_on_created_at"
    t.index ["status"], name: "index_organizations_on_status"
    t.index ["updated_at"], name: "index_organizations_on_updated_at"
    t.index ["url"], name: "index_organizations_on_url", unique: true
  end

  create_table "organizations_users", comment: "Copy of OrganizationUsers table", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at"
    t.integer "organization_id"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["created_at"], name: "index_organizations_users_on_created_at"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["updated_at"], name: "index_organizations_users_on_updated_at"
    t.index ["user_id", "organization_id"], name: "index_organizations_users_on_user_id_and_organization_id", unique: true
  end

  create_table "people", comment: "Copy of People table", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email_address", comment: "Person email address, cached from BGS"
    t.string "first_name", limit: 50, comment: "Person first name, cached from BGS"
    t.string "last_name", limit: 50, comment: "Person last name, cached from BGS"
    t.string "middle_name", limit: 50, comment: "Person middle name, cached from BGS"
    t.string "name_suffix", limit: 20, comment: "Person name suffix, cached from BGS"
    t.string "participant_id", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_people_on_created_at"
    t.index ["participant_id"], name: "index_people_on_participant_id"
    t.index ["updated_at"], name: "index_people_on_updated_at"
  end

  create_table "tasks", comment: "Denormalized Tasks with User/Organization", force: :cascade do |t|
    t.bigint "appeal_id", null: false, comment: "tasks.appeal_id"
    t.string "appeal_type", null: false, comment: "tasks.appeal_type"
    t.datetime "assigned_at", comment: "tasks.assigned_at"
    t.bigint "assigned_by_id", comment: "tasks.assigned_by_id"
    t.string "assigned_by_user_css_id", limit: 20, comment: "users.css_id"
    t.string "assigned_by_user_full_name", limit: 255, comment: "users.full_name"
    t.string "assigned_by_user_sattyid", limit: 20, comment: "users.sattyid"
    t.bigint "assigned_to_id", null: false, comment: "tasks.assigned_to_id"
    t.string "assigned_to_org_name", limit: 255, comment: "organizations.name"
    t.string "assigned_to_org_type", limit: 50, comment: "organizations.type"
    t.string "assigned_to_type", null: false, comment: "tasks.assigned_to_type"
    t.string "assigned_to_user_css_id", limit: 20, comment: "users.css_id"
    t.string "assigned_to_user_full_name", limit: 255, comment: "users.full_name"
    t.string "assigned_to_user_sattyid", limit: 20, comment: "users.sattyid"
    t.datetime "closed_at", comment: "tasks.closed_at"
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.text "instructions", default: [], comment: "tasks.instructions", array: true
    t.bigint "parent_id", comment: "tasks.parent_id"
    t.datetime "placed_on_hold_at", comment: "tasks.placed_on_hold_at"
    t.datetime "started_at", comment: "tasks.started_at"
    t.datetime "task_created_at", comment: "tasks.created_at"
    t.bigint "task_id", null: false, comment: "tasks.id"
    t.string "task_status", limit: 20, null: false, comment: "tasks.status"
    t.string "task_type", limit: 50, null: false, comment: "tasks.type"
    t.datetime "task_updated_at", comment: "tasks.updated_at"
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.index ["appeal_type", "appeal_id"], name: "index_tasks_on_appeal_type_and_appeal_id"
    t.index ["assigned_to_type", "assigned_to_id"], name: "index_tasks_on_assigned_to_type_and_assigned_to_id"
    t.index ["created_at"], name: "index_tasks_on_created_at"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
    t.index ["task_id"], name: "index_tasks_on_task_id"
    t.index ["task_status"], name: "index_tasks_on_task_status"
    t.index ["task_type"], name: "index_tasks_on_task_type"
    t.index ["updated_at"], name: "index_tasks_on_updated_at"
  end

  create_table "users", comment: "Combined Caseflow/VACOLS user lookups", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.string "css_id", limit: 20, null: false, comment: "CSEM (Active Directory) username"
    t.string "email", limit: 255, comment: "CSEM email"
    t.string "full_name", limit: 255, comment: "CSEM full name"
    t.datetime "last_login_at"
    t.string "roles", array: true
    t.string "sactive", limit: 1
    t.string "sattyid", limit: 20
    t.string "selected_regional_office", limit: 255, comment: "CSEM regional office"
    t.string "slogid", limit: 20
    t.string "smemgrp", limit: 8, comment: "VACOLS cached_user_attributes.smemgrp"
    t.string "stafkey", limit: 20
    t.string "station_id", limit: 20, null: false, comment: "CSEM station"
    t.string "status", limit: 20, default: "active", comment: "Whether or not the user is an active user of caseflow"
    t.datetime "status_updated_at", comment: "When the user's status was last updated"
    t.string "stitle", limit: 16, comment: "VACOLS cached_user_attributes.stitle"
    t.string "svlj", limit: 1
    t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"
    t.integer "user_id", null: false, comment: "ID of the User"
    t.index "upper((css_id)::text)", name: "index_users_on_upper_css_id_text", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["status"], name: "index_users_on_status"
    t.index ["updated_at"], name: "index_users_on_updated_at"
  end

end
