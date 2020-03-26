# frozen_string_literal: true

module VacolsHelper
  # This is the timezone of the VACOLS server in the VA data center, not the timezone of the
  # Rails server (even though they might, at times, be the same value).
  VACOLS_DEFAULT_TIMEZONE = "America/New_York"

  # There is a bug in Vacols where timestamps are saved in local time with UTC timezone
  # for example, Fri, 28 Jul 2017 14:28:01 UTC +00:00 is actually an EST time with UTC timezone
  def self.local_time_with_utc_timezone
    value = Time.zone.now.in_time_zone(VACOLS_DEFAULT_TIMEZONE)
    Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
  end

  # The same method as above that returns the date only
  def self.local_date_with_utc_timezone
    local_time_with_utc_timezone.beginning_of_day
  end

  def self.format_datetime_with_utc_timezone(input_datetime)
    return if input_datetime.nil?

    value = input_datetime.in_time_zone(VACOLS_DEFAULT_TIMEZONE)
    Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
  end

  # dates in VACOLS are incorrectly recorded as UTC.
  def self.normalize_vacols_datetime(datetime)
    return nil unless datetime

    utc_datetime = datetime.in_time_zone("UTC")

    Time.zone.local(
      utc_datetime.year,
      utc_datetime.month,
      utc_datetime.day,
      utc_datetime.hour,
      utc_datetime.min,
      utc_datetime.sec
    )
  end

  def self.validate_presence(hash, required_fields)
    missing_keys = []
    required_fields.each { |k| missing_keys << k unless hash[k] }
    unless missing_keys.empty?
      msg = "Required fields: #{missing_keys.join(', ')}"
      fail Caseflow::Error::MissingRequiredFieldError, msg
    end
  end

  def self.day_only_str(date_time)
    Time.use_zone(VACOLS_DEFAULT_TIMEZONE) do
      Time.zone.local(
        date_time.year,
        date_time.month,
        date_time.day
      ).strftime("%Y-%m-%d")
    end
  end
end
