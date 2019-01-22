module HearingDayMapper
  class InvalidRegionalOfficeError < StandardError
  end

  COLUMN_NAME_REVERSE_MAP = {
    hearing_pkseq: :id,
    hearing_type: :request_type,
    hearing_date: :scheduled_for,
    folder_nr: :regional_office,
    room: :room,
    board_member: :judge_id,
    team: :team,
    adduser: :created_by,
    addtime: :created_at,
    mduser: :updated_by,
    mdtime: :updated_at,
    vdbvapoc: :bva_poc,
    notes: :notes,
    judge_last_name: :judge_last_name,
    judge_middle_name: :judge_middle_name,
    judge_first_name: :judge_first_name
  }.freeze

  class << self
    def hearing_day_field_validations(hearing_info)
      {
        hearing_pkseq: hearing_info[:hearing_pkseq],
        request_type: translate_request_type(hearing_info[:request_type]),
        scheduled_for: hearing_info[:scheduled_for],
        room: hearing_info[:room],
        regional_office: validate_regional_office(hearing_info[:regional_office]),
        judge_id: hearing_info[:judge_id],
        team: hearing_info[:team],
        bva_poc: hearing_info[:bva_poc],
        notes: hearing_info[:notes],
        judge_last_name: hearing_info[:judge_last_name],
        judge_middle_name: hearing_info[:judge_middle_name],
        judge_first_name: hearing_info[:judge_first_name]
      }.select { |k, _v| hearing_info.keys.map(&:to_sym).include? k }
    end

    def translate_request_type(request_type)
      return if request_type.nil?

      (request_type.length > 1) ? HearingDay::REQUEST_TYPES[request_type.to_sym] : request_type
    end

    def validate_regional_office(regional_office)
      return if regional_office.nil?
      return regional_office if regional_office == HearingDay::REQUEST_TYPES[:central]

      ro = begin
        RegionalOffice.find!(regional_office)
           rescue RegionalOffice::NotFoundError
             nil
      end
      fail(InvalidRegionalOfficeError) if ro.nil?

      ro.key
    end

    def city_for_regional_office(regional_office)
      return if regional_office.nil?

      ro = begin
        RegionalOffice.find!(regional_office)
           rescue RegionalOffice::NotFoundError
             nil
      end
      return "" if ro.nil?

      "#{ro.city}, #{ro.state}"
    end

    def label_for_room(room_nbr)
      return if room_nbr.nil?

      HearingRooms.find!(room_nbr).label
    end

    def label_for_type(request_type)
      HearingDay::REQUEST_TYPES.key(request_type).to_s.capitalize
    end
  end
end
