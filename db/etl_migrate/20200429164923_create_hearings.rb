class CreateHearings < ActiveRecord::Migration[5.2]
  def change
    create_table :hearings, comment: "Denormalized hearings" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      # Hearing attributes
      t.bigint "hearing_id", null: false, comment: "ID of the Hearing"
      t.integer "appeal_id", null: false, comment: "ID of the associated Appeal"
      t.index ["hearing_id"]
      t.index ["appeal_id"]

      t.datetime "hearing_created_at", comment: "hearings.created_at"
      t.datetime "hearing_updated_at", comment: "hearings.updated_at"
      t.index ["hearing_created_at"]
      t.index ["hearing_updated_at"]

      t.string "bva_poc", comment: "hearings.bva_poc"
      t.bigint "created_by_id", comment: "The ID of the user who created the Hearing"
      t.string "created_by_user_css_id", limit: 20, comment: "users.css_id"
      t.string "created_by_user_full_name", limit: 255, comment: "users.full_name"
      t.string "created_by_user_sattyid", limit: 20, comment: "users.sattyid"
      t.string "disposition", comment: "hearings.disposition"
      t.boolean "evidence_window_waived", comment: "hearings.evidence_window_waived"
      t.integer "hearing_day_id", null: false, comment: "hearings.hearing_day_id"
      t.index ["hearing_day_id"]

      t.integer "judge_id", comment: "hearings.judge_id"
      t.string "military_service", comment: "hearings.military_service"
      t.string "notes", comment: "hearings.notes"
      t.boolean "prepped", comment: "hearings.prepped"
      t.string "representative_name", comment: "hearings.representative_name"
      t.string "room", comment: "hearings.room"
      t.time "scheduled_time", null: false, comment: "hearings.scheduled_time"
      t.text "summary", comment: "hearings.summary"
      t.boolean "transcript_requested", comment: "hearings.transcript_requested"
      t.date "transcript_sent_date", comment: "hearings.transcript_sent_date"

      t.bigint "updated_by_id", comment: "The ID of the user who most recently updated the Hearing"
      t.string "updated_by_user_css_id", limit: 20, comment: "users.css_id"
      t.string "updated_by_user_full_name", limit: 255, comment: "users.full_name"
      t.string "updated_by_user_sattyid", limit: 20, comment: "users.sattyid"

      t.uuid "uuid", null: false, comment: "Unique identifier for the Hearing"
      t.index ["uuid"]

      t.string "witness", comment: "hearings.witness"

      # virtual attribute to capture hearing request type
      t.string "hearing_request_type", null: false, comment: "Calculated based on virtual_hearings and hearing_day.request_type"
      t.index ["hearing_request_type"]

      # Hearing Day attributes
      t.string "hearing_day_bva_poc", comment: "hearing_days.bva_poc"
      t.datetime "hearing_day_created_at", null: false, comment: "hearing_days.created_at"
      t.bigint "hearing_day_created_by_id", null: false, comment: "The ID of the user who created the Hearing Day"
      t.string "hearing_day_created_by_user_css_id", limit: 20, comment: "users.css_id"
      t.string "hearing_day_created_by_user_full_name", limit: 255, comment: "users.full_name"
      t.string "hearing_day_created_by_user_sattyid", limit: 20, comment: "users.sattyid"
      t.datetime "hearing_day_deleted_at", comment: "hearing_days.deleted_at"
      t.integer "hearing_day_judge_id", comment: "hearing_days.judge_id"
      t.boolean "hearing_day_lock", comment: "hearing_days.lock"
      t.text "hearing_day_notes", comment: "hearing_days.notes"
      t.string "hearing_day_regional_office", comment: "hearing_days.regional_office"
      t.string "hearing_day_request_type", null: false, comment: "hearing_days.request_type"
      t.string "hearing_day_room", comment: "The room at BVA where the hearing will take place"
      t.date "hearing_day_scheduled_for", null: false, comment: "hearing_days.scheduled_for"
      t.datetime "hearing_day_updated_at", null: false, comment: "hearing_days.updated_at"
      t.bigint "hearing_day_updated_by_id", null: false, comment: "The ID of the user who most recently updated the Hearing Day"
      t.string "hearing_day_updated_by_user_css_id", limit: 20, comment: "users.css_id"
      t.string "hearing_day_updated_by_user_full_name", limit: 255, comment: "users.full_name"
      t.string "hearing_day_updated_by_user_sattyid", limit: 20, comment: "users.sattyid"

      t.index ["hearing_day_created_at"]
      t.index ["hearing_day_deleted_at"]
      t.index ["hearing_day_updated_at"]

      # Hearing Location attributes
      t.bigint "hearing_location_id", comment: "hearing_locations.id"
      t.string "hearing_location_address", comment: "hearing_locations.address"
      t.string "hearing_location_city", comment: "hearing_locations.city"
      t.string "hearing_location_classification", comment: "hearing_locations.classification"
      t.datetime "hearing_location_created_at", comment: "hearing_locations.created_at"
      t.float "hearing_location_distance", comment: "hearing_locations.distance"
      t.string "hearing_location_facility_id", comment: "hearing_locations.facility_id"
      t.string "hearing_location_facility_type", comment: "hearing_locations.facility_type"
      t.string "hearing_location_name", comment: "hearing_locations.name"
      t.string "hearing_location_state", comment: "hearing_locations.state"
      t.datetime "hearing_location_updated_at", comment: "hearing_locations.updated_at"
      t.string "hearing_location_zip_code", comment: "hearing_locations.zip_code"

      t.index ["hearing_location_id"]
      t.index ["hearing_location_created_at"]
      t.index ["hearing_location_updated_at"]
    end
  end
end
