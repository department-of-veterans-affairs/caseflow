# frozen_string_literal: true

class Api::V2::HearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :address do |hearing|
    hearing.hearing_location&.address
  end
  attribute :city do |hearing|
    hearing.hearing_location&.city
  end
  attribute :appeal, &:appeal_external_id
  attribute :facility_id do |hearing|
    hearing.hearing_location&.facility_id
  end
  attribute :first_name, &:veteran_first_name
  attribute :last_name, &:veteran_last_name
  attribute :participant_id do |hearing|
    hearing.appeal.veteran.participant_id
  end
  attribute :regional_office, &:regional_office_name
  attribute :room do |hearing|
    hearing.hearing_day.room
  end
  attribute :scheduled_for, &:scheduled_for
  attribute :ssn do |hearing|
    hearing.appeal.veteran_ssn
  end
  attribute :state do |hearing|
    hearing.hearing_location&.state
  end
  attribute :timezone, &:regional_office_timezone
  attribute :zip_code do |hearing|
    hearing.hearing_location&.zip_code
  end
end
