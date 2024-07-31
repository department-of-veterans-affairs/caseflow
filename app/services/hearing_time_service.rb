# frozen_string_literal: true

# Service to handle hearing time updates consistently between VACOLS and Caseflow
# using scheduled_time_string parameter. scheduled_time_string is always in the
# regional office's time zone, or in the central office's time zone if no regional
# office is associated with the hearing.

class HearingTimeService
  CENTRAL_OFFICE_TIMEZONE = "America/New_York"

  class << self
     # do not update scheduled_datetime field through this service
    def datetime_helper(_date_string, _time_string)
      nil
    end
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def ama_scheduled_for(time_string)
    date = @hearing&.hearing_day&.scheduled_for
    time_without_zone = time_string.split(" ", 3).take(2).join(" ")
    time = "2000-01-01 #{time_without_zone}".in_time_zone(timezone_from_time_string(time_string))
    time -= 1.hour if date.to_time.dst?
    time.utc
  end

  def legacy_scheduled_for(time_string)
    date_string = @hearing&.hearing_day&.scheduled_for
    time_without_zone = time_string.split(" ", 3).take(2).join(" ")
    "#{date_string} #{time_without_zone}".in_time_zone(timezone_from_time_string(time_string))
  end

  def scheduled_time_string
    time_to_string(local_time)
  end

  def central_office_time_string
    time_to_string(central_office_time)
  end

  def local_time
    # returns the date and time a hearing is scheduled for in the regional
    # office's time zone; or the central office's time zone if no regional
    # office is associated with the hearing.

    # for AMA hearings, return the hearing object's scheduled_for
    return @hearing.scheduled_for if @hearing.is_a?(Hearing)

    # for legacy hearings, convert to the regional office's time zone

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

  def central_office_time
    local_time.in_time_zone(CENTRAL_OFFICE_TIMEZONE)
  end

  def time_to_string(time)
    tz = ActiveSupport::TimeZone::MAPPING.key(@hearing.regional_office_timezone)

    "#{time.strftime('%l:%M %p')} #{tz}".lstrip
  end
end
