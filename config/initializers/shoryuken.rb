require "#{Rails.root}/app/jobs/middleware/job_monitoring_middleware.rb"
require "#{Rails.root}/app/jobs/middleware/job_prometheus_metric_middleware"
require "#{Rails.root}/app/jobs/middleware/job_raven_reporter_middleware"
require "#{Rails.root}/app/jobs/middleware/job_request_store_middleware"

# set up default exponential backoff parameters
ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
  .shoryuken_options(retry_intervals: [3.seconds, 1.minute, 5.minutes, 30.minutes, 1.hour, 4.hours])

Shoryuken.configure_server do |config|
  # Replace Rails logger so messages are logged wherever Shoryuken is logging
  # Note: this entire block is only run by the processor, so we don't overwrite
  #       the logger when the app is running as usual.

  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Rails.application.config.log_level

  # config.server_middleware do |chain|
  #  chain.add Shoryuken::MyMiddleware
  # end

  # For dynamically adding queues prefixed by Rails.env
  # %w(queue1 queue2) do |name|
  #   Shoryuken.add_queue("#{Rails.env}_#{name}, 1)
  # end

  # set up monitoring middleware
  config.server_middleware do |chain|
    chain.add JobMonitoringMiddleware
    chain.add JobPrometheusMetricMiddleware
    chain.add JobRavenReporterMiddleware
    chain.add JobRequestStoreMiddleware
  end
end
