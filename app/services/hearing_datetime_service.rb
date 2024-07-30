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

  def poa_time
    binding.pry
  end

  def central_office_time
    local_time.in_time_zone(CENTRAL_OFFICE_TIMEZONE)
  end

  def central_office_time_string
    central_office_time.strftime("%Y-%m-%d %I:%M %p %z")
  end

  def scheduled_time_string
    tz = ActiveSupport::TimeZone::MAPPING.key(@hearing.scheduled_in_timezone)

    "#{local_time.strftime("%l:%M %p")} #{tz}".lstrip
  end

  def appellant_time
    binding.pry
  end

  def time_to_string(time)
    binding.pry
  end

  def scheduled_for
    @hearing.scheduled_datetime.in_time_zone(@hearing.scheduled_in_timezone)
  end
end
