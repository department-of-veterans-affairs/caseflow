# frozen_string_literal: true

module Types
  class HearingDayType < Types::BaseObject
    description "HearingDay groups hearings, both AMA and legacy, by a regional office and a room at the BVA.
      Hearing Admin can create a HearingDay either individually or in bulk at the begining of
      each year by uploading bunch of spreadsheets.

      Each HearingDay has a request type which applies to all hearings associated for that day.
      Request types:
        'V' (also known as video hearing):
            The veteran/appellant travels to a regional office to have a hearing through video conference
            with a VLJ (Veterans Law Judge) who joins from the board at Washington D.C.
        'C' (also known as Central):
            The veteran/appellant travels to the board in D.C to have a in-person hearing with the VLJ.
        'T' (also known as travel board)
            The VLJ travels to the the Veteran/Appellant's closest regional office to conduct the hearing.

      If the request type is video('V'), then the HearingDay has a regional office associated.
      Currently, a video hearing can be switched to a virtual hearing represented by VirtualHearing.

      Each HearingDay has a maximum number of hearings that can be held which is either based on the
      timezone of associated regional office or 12 if the request type is central('C).

      A HearingDay can be assigned to a judge."

    field :id, ID, null: false
    field :bva_poc, String, null: false do
      description "Hearing coordinator's full name"
    end

    field :created_by, Types::UserType, null: true do
      description "User who originally created this hearing day"
    end

    # Timestamps
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :first_slot_time, String, null: true do
      description "The first time slot available; interpreted as the local time at Central office or the RO"
    end

    field :judge, Types::JudgeType, null: true do
      description "The judge associated with this hearing day"
    end

    field :lock, Boolean, null: true do
      description "Determines if the hearing day is locked and can't be edited"
    end

    field :notes, String, null: true do
      description "Any notes about hearing day"
    end

    field :number_of_slots, Int, null: true do
      description "The number of time slots possible for this day"
    end

    field :regional_office, String, null: true do
      description "Regional office key associated with hearing day"
    end

    field :request_type, String, null: true do
      description "Hearing request types for all associated hearings; can be one of: 'T', 'C' or 'V'"
    end

    field :room, String, null: true do
      description "The room at BVA where the hearing will take place"
    end

    field :scheduled_for, Types::CustomScalars::ISO8601Date, null: false do
      description "The date when all associated hearings will take place"
    end

    field :slot_length_minutes, Int, null: true do
      description "The length in minutes of each time slot for this day"
    end

    field :updated_by, Types::UserType, null: true do
      description "User to have last updated this hearing day"
    end

    field :hearings, Types::HearingType.connection_type, null: true do
      description "Hearings scheduled to take place on this hearing day"
    end

    delegate :judge, :created_by, :updated_by, :hearings, to: :object

    def notes
      # Restrict access to docket notes
      RequestStore[:current_user]&.vso_employee? ? nil : object.notes
    end
  end
end
