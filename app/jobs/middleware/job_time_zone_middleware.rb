# frozen_string_literal: true

# This middleware ensures all jobs run in UTC.
class JobTimeZoneMiddleware
  def call(_worker, _queue, _msg, body)
    job_class = body["job_class"]
    current_tz = Time.zone.name
    if current_tz != "UTC"
      Rails.logger.info("#{job_class} current timezone is #{current_tz}")
    end
    Time.use_zone("UTC") do
      yield
    end
  end
end
