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
  attribute :readable_request_type do |hearing_day, params|
    get_readable_request_type(hearing_day, params)
  end
  attribute :regional_office do |object|
    HearingDayMapper.city_for_regional_office(object.regional_office) unless object.regional_office.nil?
  end
  attribute :regional_office_key, &:regional_office
  attribute :request_type
  attribute :room do |object|
    HearingRooms.find!(object.room).label unless object.room.nil?
  end
  attribute :scheduled_for
  attribute :total_slots
  attribute :slot_length_minutes
  attribute :begins_at
  attribute :updated_by_id
  attribute :updated_at

  def self.get_readable_request_type(hearing_day, params)
    if params[:video_hearing_days_request_types].nil?
      fail ArgumentError, "params must have video_hearing_days_request_types"
    end

    # `video_hearing_days_request_types` should be constructed with
    # HearingDayRequestTypeQuery. It is an optimized way to get the request type
    # for a video hearing day, which can vary depending on how many virtual hearings
    # a video hearing day has.
    request_type = params[:video_hearing_days_request_types][hearing_day.id]

    return request_type if request_type.present?

    Hearing::HEARING_TYPES[hearing_day.request_type.to_sym]
  end

  def self.serialize_collection(hearing_days)
    video_hearing_days_request_types = HearingDayRequestTypeQuery.new.call

    ::HearingDaySerializer.new(
      hearing_days,
      collection: true,
      params: { video_hearing_days_request_types: video_hearing_days_request_types }
    ).serializable_hash[:data].map { |hearing_day| hearing_day[:attributes] }
  end
end
