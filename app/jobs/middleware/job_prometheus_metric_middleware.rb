class JobPrometheusMetricMiddleware
  def call(_worker, _queue, _msg, body)
    job_class = body["job_class"]

    yield

  rescue
    PrometheusService.background_jobs_error_counter.increment(name: job_class)

    # reraise the same error. This lets Shoryuken's retry logic kick off
    # as normal, but we still capture the error
    raise
  ensure
    PrometheusService.background_jobs_attempt_counter.increment(name: job_class)

    PrometheusService.push_metrics!
  end
end
