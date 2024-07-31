# frozen_string_literal: true

class HearingDatetimeService
  CENTRAL_OFFICE_TIMEZONE = "America/New_York"

  class << self
    # returns Time object in the timezone specified in the supplied scheduled_time_string
    def datetime_helper(date_string, time_string)
      time_without_zone = time_string.split(" ", 3).take(2).join(" ")
      "#{date_string} #{time_without_zone}".in_time_zone(timezone_from_time_string(time_string))
    end

    def timezone_from_time_string(scheduled_time_string)
      time_str_split = scheduled_time_string.split(" ", 3)

      tz_str = ActiveSupport::TimeZone::MAPPING[time_str_split[2]]
      tz_str = ActiveSupport::TimeZone::MAPPING.key(time_str_split[2]) if tz_str.nil?

      begin
        ActiveSupport::TimeZone.find_tzinfo(tz_str).name
      rescue TZInfo::InvalidTimezoneIdentifier => error
        Raven.capture_exception(error)
        Rails.logger.info("#{error}: Invalid timezone #{tz_str} for hearing day")
        raise error
      end
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def local_time
    @hearing.scheduled_for
  end

  def legacy_scheduled_for(time_string)
    self.class.datetime_helper(@hearing&.hearing_day&.scheduled_for, time_string)
  end

  def ama_scheduled_for(_time_string)
    nil
  end

  def central_office_time
    local_time.in_time_zone(CENTRAL_OFFICE_TIMEZONE)
  end

  def central_office_time_string
    central_office_time.strftime("%Y-%m-%d %I:%M %p %z")
  end

  def scheduled_time_string
    tz = ActiveSupport::TimeZone::MAPPING.key(@hearing.scheduled_in_timezone)

    "#{local_time.strftime('%l:%M %p')} #{tz}".lstrip
  end

  # the below methods could potentially be moved to Hearings::CalendarTemplateHelper

  def normalized_time(timezone)
    return local_time if timezone.nil?

    # throws an error here if timezone is invalid
    local_time.in_time_zone(timezone)
  end

  # hearing time in poa timezone
  def poa_time
    # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
    representative_tz_from_recipient = @hearing.representative_recipient&.timezone
    return normalized_time(representative_tz_from_recipient) if representative_tz_from_recipient.present?
    # If there's a virtual hearing, use that tz even if it's empty
    return normalized_time(@hearing.virtual_hearing[:representative_tz]) if @hearing.virtual_hearing.present?

    # No recipient and no virtual hearing? Use the normalized_time fallback
    normalized_time(nil)
  end

  # hearing time in appellant timezone
  def appellant_time
    # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
    appellant_tz_from_recipient = @hearing.appellant_recipient&.timezone
    return normalized_time(appellant_tz_from_recipient) if appellant_tz_from_recipient.present?
    # If there's a virtual hearing, use that tz even if it's empty
    return normalized_time(@hearing.virtual_hearing[:appellant_tz]) if @hearing.virtual_hearing.present?

    # No recipient and no virtual hearing? Use the normalized_time fallback
    normalized_time(nil)
  end
end
