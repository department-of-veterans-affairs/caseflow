module VacolsHelper
  # There is a bug in Vacols where timestamps are saved in local time with UTC timezone
  # for example, Fri, 28 Jul 2017 14:28:01 UTC +00:00 is actually an EST time with UTC timezone
  def self.local_time_with_utc_timezone
    value = Time.zone.now.in_time_zone("Eastern Time (US & Canada)")
    Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
  end
end