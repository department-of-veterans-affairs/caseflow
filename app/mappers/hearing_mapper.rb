# frozen_string_literal: true

module HearingMapper
  class InvalidHoldOpenError < StandardError; end
  class InvalidAodError < StandardError; end
  class InvalidDispositionError < StandardError; end
  class InvalidTranscriptRequestedError < StandardError; end
  class InvalidNotesError < StandardError; end
  class InvalidAddOnError < StandardError; end
  class InvalidRepresentativeNameError < StandardError; end

  class << self
    def hearing_fields_to_vacols_codes(hearing_info)
      {
        scheduled_for: VacolsHelper.format_datetime_with_utc_timezone(hearing_info[:scheduled_for]),
        notes: notes_to_vacols_format(hearing_info[:notes]),
        disposition: disposition_to_vacols_format(hearing_info[:disposition], hearing_info.keys),
        hold_open: hold_open_to_vacols_format(hearing_info[:hold_open]),
        aod: aod_to_vacols_format(hearing_info[:aod]),
        add_on: add_on_to_vacols_format(hearing_info[:add_on]),
        transcript_requested: transcript_requested_to_vacols_format(hearing_info[:transcript_requested]),
        representative_name: representative_name_to_vacols_format(hearing_info[:representative_name]),
        folder_nr: hearing_info[:folder_nr],
        room: hearing_info[:room],
        bva_poc: hearing_info[:bva_poc],
        judge_id: judge_to_vacols_format(hearing_info[:judge_id])
      }.select do |k, _v|
        hearing_info.keys.map(&:to_sym).include?(k)
        # only send updates to key/values that are passed
      end
    end

    def bfha_vacols_code(hearing_record)
      case hearing_record.hearing_disp
      when "H"
        code_based_on_request_type(hearing_record.hearing_type.to_sym)
      when "P"
        nil
      when "C"
        "5"
      when "N"
        "5"
      end
    end

    # The TB and Video hearing datetime reflect the timezone of the local RO,
    # So we append the timezone based on the regional office location
    # And then convert the date to Eastern Time
    # asctime - returns a canonical string representation of time
    def datetime_based_on_type(datetime:, regional_office_key:, type:)
      datetime = VacolsHelper.normalize_vacols_datetime(datetime)
      return datetime if type == HearingDay::REQUEST_TYPES[:central]

      datetime.asctime.in_time_zone(timezone(regional_office_key)).in_time_zone("Eastern Time (US & Canada)")
    end

    def timezone(regional_office_key)
      regional_office = RegionalOffice::CITIES[regional_office_key] ||
                        RegionalOffice::SATELLITE_OFFICES[regional_office_key] || {}
      regional_office[:timezone]
    end

    private

    def code_based_on_request_type(type)
      return "1" if type == :C
      return "2" if type == :T
      return "6" if type == :V
    end

    def representative_name_to_vacols_format(value)
      return if value.nil?
      fail(InvalidRepresentativeNameError) if !value.is_a?(String)

      value[0, 25]
    end

    def notes_to_vacols_format(value)
      return if value.nil?
      fail(InvalidNotesError) if !value.is_a?(String)

      value[0, 100]
    end

    def disposition_to_vacols_format(value, keys)
      vacols_code = VACOLS::CaseHearing::HEARING_DISPOSITIONS.key(value)
      # disposition cannot be nil
      fail(InvalidDispositionError) if keys.include?(:disposition) && (value.blank? || vacols_code.blank?)

      vacols_code
    end

    def hold_open_to_vacols_format(value)
      fail(InvalidHoldOpenError) if !value.nil? && (!value.is_a?(Integer) || value < 0 || value > 90)

      value
    end

    def aod_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::HEARING_AODS.key(value.try(:to_sym))
      fail(InvalidAodError) if !value.nil? && vacols_code.blank?

      vacols_code
    end

    def add_on_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::BOOLEAN_MAP.key(value)
      fail(InvalidAddOnError) if value && vacols_code.blank?

      vacols_code
    end

    def transcript_requested_to_vacols_format(value)
      vacols_code = VACOLS::CaseHearing::BOOLEAN_MAP.key(value)
      fail(InvalidTranscriptRequestedError) if value && vacols_code.blank?

      vacols_code
    end

    def judge_to_vacols_format(value)
      value.nil? ? nil : User.find(value).vacols_attorney_id
    end
  end
end
