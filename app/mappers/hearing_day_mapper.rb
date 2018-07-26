module HearingDayMapper
  class InvalidRegionalOfficeError < StandardError
  end

  COLUMN_NAME_REVERSE_MAP = {
    hearing_pkseq: :id,
    hearing_type: :hearing_type,
    hearing_date: :hearing_date,
    folder_nr: :regional_office,
    room: :room_info,
    board_member: :judge_id,
    judge_name: :judge_name,
    team: :team,
    mduser: :updated_by,
    mdtime: :updated_on
  }.freeze

  class << self
    def hearing_day_field_validations(hearing_info)
      {
        hearing_type: translate_hearing_type(hearing_info[:hearing_type]),
        hearing_date: hearing_info[:hearing_date],
        room_info: hearing_info[:room_info],
        regional_office: validate_regional_office(hearing_info[:regional_office]),
        judge_id: hearing_info[:judge_id],
        team: hearing_info[:team]
      }.select { |k, _v| hearing_info.keys.map(&:to_sym).include? k }
    end

    def translate_hearing_type(hearing_type)
      return if hearing_type.nil?

      (hearing_type.length > 1) ? HearingDay::HEARING_TYPES[hearing_type.to_sym] : hearing_type
    end

    def validate_regional_office(regional_office)
      return if regional_office.nil?

      ro = RegionalOffice.find!(regional_office)
      fail(InvalidRegionalOfficeError) if ro.nil?
      ro.key
    end

    def city_for_regional_office(regional_office)
      return if regional_office.nil?

      ro = RegionalOffice.find!(regional_office)
      "#{ro.city}, #{ro.state}"
    end

    def label_for_room(room_nbr)
      return if room_nbr.nil?

      HearingRooms.find!(room_nbr).label
    end

    def label_for_type(hearing_type)
      HearingDay::HEARING_TYPES.key(hearing_type).to_s.capitalize
    end
  end
end
