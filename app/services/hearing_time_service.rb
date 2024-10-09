# frozen_string_literal: true

# Service to handle hearing time updates consistently between VACOLS and Caseflow
# using scheduled_time_string parameter. scheduled_time_string is always in the
# regional office's time zone, or in the central office's time zone if no regional
# office is associated with the hearing.

class HearingTimeService
  CENTRAL_OFFICE_TIMEZONE = "America/New_York"

  class << self
    def time_to_string(time, hearing)
      datetime = time.to_datetime

      tz = ActiveSupport::TimeZone::MAPPING.key(hearing.regional_office_timezone)

      "#{datetime.strftime('%l:%M %p')} #{tz}".lstrip
    end

    # Used to satisfy an interface for a façade between {HearingDatetimeService}
    #  and {HearingTimeService}. It will always return nil since this service
    #  does not pertain to datetime processing.
    # @return [nil] nil will always be returned.
    def prepare_datetime_for_storage(**_args)
      nil
    end

    # Checks the time_string value and returns the formatted time in %H:%M
    # @return [String, nil] - Time string in "%H:%M" format
    # @example Extract the hour and minute from a string.
    #   process_scheduled_time("1:00 PM Eastern Time (US & Canada)") #=> "13:00"
    def process_scheduled_time(time_string)
      return nil if time_string.blank?

      Time.strptime(time_string, "%I:%M %p").strftime("%H:%M")
    end

    private

    def pad_time(time)
      "0#{time}".chars.last(2).join
    end

    def remove_time_string_params(params)
      params.reject { |param| param.to_sym == :scheduled_time_string }
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def scheduled_time_string
    self.class.time_to_string(local_time, @hearing)
  end

  def central_office_time_string
    datetime = central_office_time.to_datetime

    "#{datetime.strftime('%l:%M %p')} Eastern Time (US & Canada)".lstrip
  end

  def local_time
    # for AMA hearings, return the hearing object's scheduled_for
    return @hearing.scheduled_for if @hearing.is_a?(Hearing)

    # for legacy hearings with nil scheduled_in_timezone, convert to the regional office's time zone.
    # if the hearing's regional_office_timezone is nil, assume this is a
    # central office hearing (eastern time)
    regional_office_timezone = @hearing.regional_office_timezone || CENTRAL_OFFICE_TIMEZONE
    scheduled_for = @hearing.scheduled_for

    # There is a bug in Vacols where timestamps are saved in local time with UTC timezone
    # for example, Fri, 28 Jul 2017 14:28:01 UTC +00:00 is actually an EST time with UTC timezone
    # This code is to account for this bug.
    if scheduled_for.utc?
      return scheduled_for.strftime("%a, %d %b %Y %H:%M:%S").in_time_zone(regional_office_timezone)
    end

    # convert the hearing time returned by LegacyHearing.scheduled_for
    # to the regional office timezone
    @hearing.scheduled_for.in_time_zone(regional_office_timezone)
  end

  def central_office_time
    local_time.in_time_zone(CENTRAL_OFFICE_TIMEZONE)
  end

  # Casts incoming scheduled_time_strings into Eastern Time, and then into a quasi-UTC Time object.
  # @see - HearingMapper.datetime_based_on_type is where these values are coverted to their correct
  #   local time whenever retreiving them from the database.
  #
  # Used to facilitate updates to hearing times submitted via the {LegacyHearingUpdateForm}
  #
  # @param date [Date] a Date object for which a hearing will be scheduled.
  # @param time_string [String] a formatted string with scheduling details. ex: 12:00 PM Eastern Time (US & Canada).
  # @return [Time] The time a hearing is set to take place in cast to UTC time.
  # @return [nil] If either the date or time_string params are absent.
  def process_legacy_scheduled_time_string(date:, time_string:)
    return nil unless date && time_string

    hour, min = self.class.process_scheduled_time(time_string).split(":")
    time = date.to_datetime
    unformatted_time = Time.use_zone(VacolsHelper::VACOLS_DEFAULT_TIMEZONE) do
      Time.zone.now.change(
        year: time.year, month: time.month, day: time.day, hour: hour.to_i, min: min.to_i
      )
    end

    VacolsHelper.format_datetime_with_utc_timezone(unformatted_time)
  end
end
