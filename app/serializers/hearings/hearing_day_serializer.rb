# frozen_string_literal: true

class HearingDaySerializer
  include FastJsonapi::ObjectSerializer

  attribute :bva_poc
  attribute :created_at
  attribute :created_by_id
  attribute :deleted_at
  attribute :id
  attribute :judge_first_name
  attribute :judge_id
  attribute :judge_last_name
  attribute :lock
  attribute :notes
  attribute :readable_request_type
  attribute :regional_office
  ## in preparation for removing json_hearing_day from hearing_day_controller
  attribute :regional_office_key, &:regional_office
  attribute :regional_office_city do |object|
    HearingDayMapper.city_for_regional_office(object.regional_office) unless object.regional_office.nil?
  end
  attribute :request_type
  attribute :room
  ## in preparation for removing json_hearing_day from hearing_day_controller
  attribute :room_label do |object|
    HearingDayMapper.label_for_room(object.room)
  end
  attribute :scheduled_for
  attribute :total_slots
  attribute :updated_by_id
  attribute :updated_at
end
