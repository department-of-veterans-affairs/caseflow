# frozen_string_literal: true

module Types
  class HearingType < Types::BaseObject
    field :id, ID, null: false do
      description "The name of this thing"
    end

    field :appeal, Types::AppealType, null: false do
      description "The name of this thing"
    end

    field :bva_poc, String, null: true do
      description "The name of this thing"
    end

    delegate :appeal, to: :object

    # t.integer "appeal_id", null: false, comment: "Appeal ID; use as FK to appeals"
    # t.string "bva_poc", comment: "Hearing coordinator full name"
    # t.datetime "created_at", comment: "Automatic timestamp when row was created."
    # t.bigint "created_by_id", comment: "The ID of the user who created the Hearing"
    # t.string "disposition", comment: "Hearing disposition; can be one of: 'held', 'postponed', 'no_show', or 'cancelled'"
    # t.boolean "evidence_window_waived", comment: "Determines whether the veteran/appelant has wavied the 90 day evidence hold"
    # t.integer "hearing_day_id", null: false, comment: "HearingDay ID; use as FK to HearingDays"
    # t.integer "judge_id", comment: "User ID of judge who will hold the hearing"
    # t.string "military_service", comment: "Periods and circumstances of military service"
    # t.string "notes", comment: "Any notes taken prior or post hearing"
    # t.boolean "prepped", comment: "Determines whether the judge has checked the hearing as prepped"
    # t.string "representative_name", comment: "Name of Appellant's representative if applicable"
    # t.string "room", comment: "The room at BVA where the hearing will take place; ported from associated HearingDay"
    # t.time "scheduled_time", null: false, comment: "Date and Time when hearing will take place"
    # t.text "summary", comment: "Summary of hearing"
    # t.boolean "transcript_requested", comment: "Determines whether the veteran/appellant has requested the hearing transcription"
    # t.date "transcript_sent_date", comment: "Date of when the hearing transcription was sent to the Veteran/Appellant"
    # t.datetime "updated_at", comment: "Timestamp when record was last updated."
    # t.bigint "updated_by_id", comment: "The ID of the user who most recently updated the Hearing"
    # t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
    # t.string "witness", comment: "Witness/Observer present during hearing"
    # t.index ["created_by_id"], name: "index_hearings_on_created_by_id"
    # t.index ["disposition"], name: "index_hearings_on_disposition"
    # t.index ["updated_at"], name: "index_hearings_on_updated_at"
    # t.index ["updated_by_id"], name: "index_hearings_on_updated_by_id"
    # t.index ["uuid"], name: "index_hearings_on_uuid"
  end
end
