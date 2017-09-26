# This middleware adds tracking for job status such as start & end time
class JobMonitoringMiddleware
  def call(worker_instance, queue, msg, body)
    job_class = body["job_class"]
    Rails.cache.write("#{job_class}_last_started_at", Time.now.utc)

    yield

    Rails.cache.write("#{job_class}_last_completed_at", Time.now.utc)
  end
end
