# This middleware adds tracking for job status such as start & end time
class JobMonitoringMiddleware

  def call(worker, msg, queue)
    job_class = msg["args"][0]["job_class"]
    Rails.cache.write("#{job_class}_last_started_at", Time.now)

    yield

    Rails.cache.write("#{job_class}_last_completed_at", Time.now)
  end

end
