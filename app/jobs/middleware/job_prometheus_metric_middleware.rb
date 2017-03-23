class JobPrometheusMetricMiddleware
  def call(worker, msg, queue)
    yield

    name = msg["args"][0]["job_class"]
  rescue => e
    PrometheusService.background_jobs_error_counter.increment(name: name)

    # reraise the same error. This lets Sidekiq's retry logic kick off
    # as normal, but we still capture the error
    raise
  ensure
    PrometheusService.background_jobs_attempt_counter.increment(name: name)
  end
end
