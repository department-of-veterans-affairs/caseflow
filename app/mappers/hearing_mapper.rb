# frozen_string_literal: true

module HearingMapper
  class InvalidHoldOpenError < StandardError; end
  class InvalidAodError < StandardError; end
  class InvalidRequestTypeError < StandardError; end
  class InvalidDispositionError < StandardError; end
  class InvalidTranscriptRequestedError < StandardError; end
  class InvalidNotesError < StandardError; end
  class InvalidAddOnError < StandardError; end
  class InvalidRepresentativeNameError < StandardError; end

  class << self
    def hearing_fields_to_vacols_codes(hearing_info)
      {
        request_type: validate_request_type(hearing_info[:request_type], hearing_info.keys),
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
      when VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled]
        "5"
      when VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held]
        code_based_on_request_type(hearing_record.hearing_type.to_sym)
      when VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:no_show]
        "5"
      when VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed]
        nil
      when VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:scheduled_in_error]
        nil
      end
    end

    # Travel Board and Video hearing datetimes reflect the timezone of
    # the local RO, so we append the timezone based on the regional
    # office location then convert the date to Eastern Time
    def datetime_based_on_type(datetime:, regional_office:, type:)
      # convert the date to UTC then cast it to Time.zone. In a
      # web process, Time.zone is set based on the session's or user's
      # timezone in ApplicationController.set_timezone
      datetime = VacolsHelper.normalize_vacols_datetime(datetime)

      # return the datetime now if this is a central hearing
      return datetime if type == HearingDay::REQUEST_TYPES[:central]

      # (1) cast the time to the time zone of the regional office, then
      # (2) convert it to Eastern Time.
      #
      # (1) asctime renders a string in the format "Thu Feb 20 08:30:00 2020";
      #     because the string has no time zone information, in_time_zone
      #     creates a Time object with the same time and date, and also the
      #     passed time zone.
      # (2) that time is then converted to Eastern Time to get the correct
      #     hearing time for the central office.
      datetime
        .asctime
        .in_time_zone(regional_office&.timezone)
        .in_time_zone(VacolsHelper::VACOLS_DEFAULT_TIMEZONE)
    end

    def notes_to_vacols_format(value)
      return if value.nil?
      fail(InvalidNotesError) if !value.is_a?(String)

      value[0, 1000]
    end

    private

    def code_based_on_request_type(type)
      return "1" if type == :C
      return "2" if type == :T
      return "6" if type == :V
      return "7" if type == :R
    end

    def representative_name_to_vacols_format(value)
      return if value.nil?
      fail(InvalidRepresentativeNameError) if !value.is_a?(String)

      value[0, 25]
    end

    def validate_request_type(value, keys)
      # request_type must be valid
      blank_value_passed = keys.include?(:request_type) && value.blank?
      invalid_value_passed = value.present? && VACOLS::CaseHearing::HEARING_TYPES.exclude?(value)

      if blank_value_passed || invalid_value_passed
        fail InvalidRequestTypeError, "\"#{value}\" is not a valid request type."
      end

      value
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
