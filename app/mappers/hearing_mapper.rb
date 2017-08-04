module HearingMapper
  class InvalidHoldOpenError < StandardError; end
  class InvalidAodError < StandardError; end
  class InvalidDispositionError < StandardError; end
  class InvalidTranscriptRequestedError < StandardError; end

  class << self
    def hearing_fields_to_vacols_codes(hearing_info)
      {
        notes: notes_to_vacols_format(hearing_info[:notes]),
        disposition: disposition_to_vacols_format(hearing_info[:disposition]),
        hold_open: hold_open_to_vacols_format(hearing_info[:hold_open]),
        aod: aod_to_vacols_format(hearing_info[:aod]),
        transcript_requested: transcript_requested_to_vacols_format(hearing_info[:transcript_requested])
      }.select { |k, _v| hearing_info.keys.include? k } # only send updates to key/values that are passed
    end

    def bfha_vacols_code(hearing_record)
      case hearing_record.hearing_disp
      when "H"
        code_based_on_hearing_type(hearing_record.hearing_type.to_sym)
      when "P"
        nil
      when "C"
        "5"
      when "N"
        "5"
      end
    end

    private

    def code_based_on_hearing_type(type)
      return "1" if type == :C
      return "2" if type == :T
      return "6" if type == :V
    end

    def notes_to_vacols_format(value)
      value.present? ? value[0, 100] : nil
    end

    def disposition_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::HEARING_DISPOSITIONS.key(value)
      fail(InvalidDispositionError) if value && vacols_code.blank?
      vacols_code
    end

    def hold_open_to_vacols_format(value)
      fail(InvalidHoldOpenError) if value && (!value.is_a?(Integer) || value < 0 || value > 90)
      value
    end

    def aod_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::HEARING_AODS.key(value)
      fail(InvalidAodError) if value && vacols_code.blank?
      vacols_code
    end

    def transcript_requested_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::BOOLEAN_MAP.key(value)
      fail(InvalidTranscriptRequestedError) if value && vacols_code.blank?
      vacols_code
    end
  end
end
