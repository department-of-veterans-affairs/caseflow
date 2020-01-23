# frozen_string_literal: true

class Api::V2::HearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :address do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.street_address
    else
      hearing.regional_office.address
    end
  end
  attribute :city do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.city
    else
      hearing.regional_office.city
    end
  end
  attribute :appeal, &:appeal_external_id
  attribute :facility_id do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.facility_id
    else
      hearing.regional_office.facility_id
    end
  end
  attribute :first_name, &:veteran_first_name
  attribute :last_name, &:veteran_last_name
  attribute :participant_id do |hearing|
    hearing.appeal.veteran.participant_id
  end
  attribute :hearing_location do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.name
    else
      hearing.regional_office.name
    end
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
    if hearing.hearing_location.present?
      hearing.hearing_location.state
    else
      hearing.regional_office.state
    end
  end
  attribute :timezone do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.timezone
    else
      hearing.regional_office.timezone
    end
  end
  attribute :zip_code do |hearing|
    if hearing.hearing_location.present?
      hearing.hearing_location.zip_code
    else
      hearing.regional_office.zip_code
    end
  end
end
