# frozen_string_literal: true

# HearingDatetimeService is intended to replace {HearingTimeService} by taking advantage of the new hearings table
# columns scheduled_in_timezone and (for AMA hearings) scheduled_datetime. The two services will work in parallel until
# hearings with nil values for those columns have been held, at which point we should be able to deprecate
# {HearingTimeService} as well as the hearings.scheduled_time column (which is unable to store the hearing date due
# to it's datatype in postgres). Until then, this class will work in parallel to {HearingTimeService} through the
# facade hearing.time as set in the module {HearingTimeConcern}.

class HearingDatetimeService
  class UnsuppliedScheduledInTimezoneError < StandardError; end

  CENTRAL_OFFICE_TIMEZONE = "America/New_York"

  class << self
    # Combines a date and time string to create a Time object.
    #
    # @param date [Date] a Date object for which a hearing will be scheduled.
    # @param time_string [String] a formatted string with scheduling details, `12:00 PM Eastern Time (US & Canada)`.
    # @return [Time] the Time object in the calculated time zone and DST offset.
    def prepare_datetime_for_storage(date:, time_string:)
      return nil unless date && time_string

      time_without_zone = time_string.split(" ", 3).take(2).join(" ")
      "#{date} #{time_without_zone}".in_time_zone(timezone_from_time_string(time_string))
    end

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
    validate_required_hearing_attrs(hearing)
    @hearing = hearing
  end

  # The time a hearing is scheduled to take place in the timezone set by
  # hearing.scheduled_in_timezone. In this class it simply serves as an alias to
  # hearing.scheduled_for, but this is necessary in that it allows us to mimic
  # #local_time in the analogous facade, {HearingTimeService}.
  #
  # @return [Time]
  def local_time
    @hearing.scheduled_for
  end

  # The time a hearing is scheduled to take place in Eastern Time.
  #
  # @return [Time]
  def central_office_time
    local_time.in_time_zone(CENTRAL_OFFICE_TIMEZONE)
  end

  # A formatted string version of the central_office_time that has the timezone formatted
  # in a metazone name e.g. "Eastern Time (US & Canada)".
  #
  # @return [String]
  def central_office_time_string
    tz = ActiveSupport::TimeZone::MAPPING.key(CENTRAL_OFFICE_TIMEZONE)

    "#{central_office_time.strftime('%l:%M %p')} #{tz}".lstrip
  end

  # A formatted string version of local_time that has the timezone formatted
  # in a metazone name e.g. "Eastern Time (US & Canada)".
  #
  # @return [String]
  def scheduled_time_string
    tz = ActiveSupport::TimeZone::MAPPING.key(@hearing.scheduled_in_timezone)
    tz ||= ActiveSupport::TimeZone::MAPPING.key(
      TIMEZONE_ALIASES[@hearing.scheduled_in_timezone]
    )

    "#{local_time.strftime('%l:%M %p')} #{tz}".lstrip
  end

  # An alias for {prepare_datetime_for_storage}
  #
  # Used to facilitate updates to hearing times submitted via the {LegacyHearingUpdateForm}
  #
  # @param date [Date] a Date object for which a hearing will be scheduled.
  # @param time_string [String] a formatted string with scheduling details, `12:00 PM Eastern Time (US & Canada)`.
  # @return [Time] A representation of when the hearing will take place in the calculated time zone and DST offset.
  def process_legacy_scheduled_time_string(date:, time_string:)
    self.class.prepare_datetime_for_storage(date: date, time_string: time_string)
  end

  private

  def validate_required_hearing_attrs(hearing)
    if hearing.scheduled_in_timezone.nil?
      error = UnsuppliedScheduledInTimezoneError
      Raven.capture_exception(error)
      Rails.logger.info("#{error}: HearingDatetimeService requires non-nil scheduled_in_timezone for a hearing.")
      fail error
    end
  end
end
