# frozen_string_literal: true

# This middleware ensures all async jobs run in UTC.
class JobTimeZoneMiddleware
  # :reek:LongParameterList
  def call(_worker, _queue, _msg, body, &block)
    job_class = body["job_class"]
    current_tz = Time.zone.name
    if current_tz != "UTC"
      Rails.logger.info("#{job_class} current timezone is #{current_tz}")
    end

    Time.use_zone("UTC", &block)
  end
end
