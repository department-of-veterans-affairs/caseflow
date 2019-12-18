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
    HearingDayMapper.label_for_room(object.room)
  end
  attribute :scheduled_for
  attribute :total_slots
  attribute :updated_by_id
  attribute :updated_at

  def self.get_readable_request_type(hearing_day, params)
    if params.key?(:hearing_days_with_virtual_hearings) && !params[:hearing_days_with_virtual_hearings].nil?
      # An optimization when serializing a collection of hearing days.
      # See HearingDaysWithVirtualHearingsQuery for how to fetch these ids.
      return "Video, Virtual" if params[:hearing_days_with_virtual_hearings].include?(hearing_day.id)
    elsif VirtualHearingRepository.hearing_day_has_virtual_hearing?(hearing_day)
      return "Video, Virtual"
    end

    Hearing::HEARING_TYPES[hearing_day.request_type.to_sym]
  end

  def self.serialize_collection(hearing_days)
    hearing_days_with_virtual_hearings = HearingDaysWithVirtualHearingsQuery.new.call
      .map(&:id)
      .to_set

    ::HearingDaySerializer.new(
      hearing_days,
      collection: true,
      params: { hearing_days_with_virtual_hearings: hearing_days_with_virtual_hearings }
    ).serializable_hash[:data].map { |hearing_day| hearing_day[:attributes] }
  end
end
