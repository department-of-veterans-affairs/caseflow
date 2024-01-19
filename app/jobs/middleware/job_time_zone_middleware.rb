# frozen_string_literal: true

# This middleware adds tracking for job status such as start & end time
class JobTimeZoneMiddleware
  def call(_worker, _queue, _msg, body)
    job_class = body["job_class"]
    byebug
    if Time.zone.name !- "UTC"
      Time.use_zone("UTC")
    end

    yield

    Time.use_zone(user.time_zone)
  end
end
