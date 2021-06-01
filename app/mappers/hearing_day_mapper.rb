# frozen_string_literal: true

module HearingDayMapper
  class InvalidRegionalOfficeError < StandardError
  end

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
        judge_first_name: hearing_info[:judge_first_name],
        number_of_slots: hearing_info[:number_of_slots],
        slot_length_minutes: hearing_info[:slot_length_minutes],
        first_slot_time: hearing_info[:first_slot_time]
      }.select { |k, _v| hearing_info.keys.map(&:to_sym).include? k }
    end

    def translate_request_type(request_type)
      return if request_type.nil?

      (request_type.length > 1) ? HearingDay::REQUEST_TYPES[request_type.to_sym] : request_type
    end

    def validate_regional_office(regional_office)
      return if regional_office.nil?

      if [HearingDay::REQUEST_TYPES[:central], HearingDay::REQUEST_TYPES[:virtual]].include?(regional_office)
        return regional_office
      end

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
  end
end
