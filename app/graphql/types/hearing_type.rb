# frozen_string_literal: true

module Types
  class HearingType < Types::BaseObject
    field :id, ID, null: false do
      description "PKID of the Hearing"
    end

    field :appeal, Types::AppealType, null: false do
      description "The appeal this hearing is associated with"
    end

    field :bva_poc, String, null: true do
      description "Hearing coordinator full name"
    end

    field :created_by, Types::UserType, null: true do
      description "User who originally created this hearing"
    end

    # Timestamps
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :disposition, String, null: true do
      description "Hearing disposition; can be one of: 'held', 'postponed', 'no_show', or 'cancelled'"
    end

    field :evidence_window_waived, Boolean, null: true do
      description "Determines whether the veteran/appelant has wavied the 90 day evidence hold"
    end

    field :hearing_day, Types::HearingType, null: false do
      description "Hearing day this hearing is scheduled on"
    end

    field :judge, Types::JudgeType, null: true do
      description "The judge set to preside over this hearing"
    end

    field :military_service, String, null: true do
      description "Periods and circumstances of military service"
    end

    field :notes, String, null: true do
      description "Any notes taken prior or post hearing"
    end

    field :prepped, Boolean, null: true do
      description "Determines whether the judge has checked the hearing as prepped"
    end

    field :representative_name, String, null: true do
      description "Determines whether the judge has checked the hearing as prepped"
    end

    field :room, String, null: true do
      description "The room at BVA where the hearing will take place"
    end

    field :room, String, null: true do
      description "The room at BVA where the hearing will take place"
    end

    field :scheduled_time, Types::CustomScalars::ISO8601Date, null: false do
      description "Date and Time when hearing will take place"
    end

    field :summary, String, null: true do
      description "Summary of hearing"
    end

    field :transcript_requested, Boolean, null: true do
      description "Determines whether the veteran/appellant has requested the hearing transcription"
    end

    field :transcript_sent_date, Types::CustomScalars::ISO8601Date, null: true do
      description "Date of when the hearing transcription was sent to the Veteran/Appellant"
    end

    field :updated_by, Types::UserType, null: true do
      description "User to have last updated this hearing day"
    end

    field :uuid, String, null: true

    field :witness, String, null: true do
      description "Witness/Observer present during hearing"
    end

    delegate :appeal, :hearing_day, :judge, :created_at, :updated_by, to: :object
  end
end
