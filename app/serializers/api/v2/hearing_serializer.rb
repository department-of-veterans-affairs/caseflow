# frozen_string_literal: true

class Api::V2::HearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :address do |hearing|
    hearing.hearing_location_or_regional_office.street_address
  end
  attribute :city do |hearing|
    hearing.hearing_location_or_regional_office.city
  end
  attribute :appeal, &:appeal_external_id
  attribute :facility_id do |hearing|
    hearing.hearing_location_or_regional_office.facility_id
  end
  attribute :first_name, &:veteran_first_name
  attribute :last_name, &:veteran_last_name
  attribute :participant_id do |hearing|
    hearing.appeal.veteran&.participant_id
  end
  attribute :hearing_location do |hearing|
    hearing.hearing_location_or_regional_office.name
  end
  attribute :is_virtual, &:virtual?
  attribute :room do |hearing|
    hearing.hearing_day.room
  end
  attribute :scheduled_for, &:scheduled_for
  attribute :ssn do |hearing|
    hearing.appeal.veteran_ssn
  end
  attribute :state do |hearing|
    hearing.hearing_location_or_regional_office.state
  end
  attribute :timezone do |hearing|
    hearing.hearing_location_or_regional_office.timezone
  end
  attribute :zip_code do |hearing|
    hearing.hearing_location_or_regional_office.zip_code
  end
end
