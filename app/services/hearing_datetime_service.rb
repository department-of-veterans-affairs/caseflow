# frozen_string_literal: true

# HearingDatetimeService is intended to replace {HearingTimeService} by taking advantage of the new hearings table
# columns scheduled_in_timezone and (for AMA hearings) scheduled_datetime. The two services will work in parallel until
# hearings with nil values for those columns have been held, at which point we should be able to deprecate
# {HearingTimeService} as well as the hearings.scheduled_time column (which is unable to store the hearing date due
# to it's datatype in postgres). Until then, this class will work in parallel to {HearingTimeService} through the
# facade hearing.time as set in the module {HearingTimeConcern}.

class HearingDatetimeService
  CENTRAL_OFFICE_TIMEZONE = "America/New_York"

  class << self
    # Combines a date and time string to create a Time object.
    #
    # @param date [Date] a Date object for which a hearing will be scheduled.
    # @param time_string [String] a formatted string with scheduling details, `12:00 PM Eastern Time (US & Canada)`.
    # @return [Time] the Time object in the calculated time zone and DST offset.
    def prepare_time_for_storage(date:, time_string:)
      return nil unless date && time_string

      time_without_zone = time_string.split(" ", 3).take(2).join(" ")
      "#{date} #{time_without_zone}".in_time_zone(timezone_from_time_string(time_string))
    end

    private

    # Converts time zone from the scheduled_time_string into a region string recognized by
    # Rails ActiveSupport::Timezone
    #
    # @param scheduled_time_string [String] Formatted time and timezone string, `12:00 PM Eastern Time (US & Canada)`.
    # @return [String] e.g. `America/New_York`
    def timezone_from_time_string(scheduled_time_string)
      tz_str = scheduled_time_string.split(" ", 3)[2]

      begin
        ActiveSupport::TimeZone.find_tzinfo(tz_str)&.name
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
end
