require "#{Rails.root}/app/jobs/middleware/job_monitoring_middleware.rb"
require "#{Rails.root}/app/jobs/middleware/job_prometheus_metric_middleware"
require "#{Rails.root}/app/jobs/middleware/job_raven_reporter_middleware"
require "#{Rails.root}/app/jobs/middleware/job_request_store_middleware"

# set up default exponential backoff parameters
ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
  .shoryuken_options(retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours])

if ENV['DEPLOY_ENV'] == 'local' or ENV['DEPLOY_ENV'] == 'development'
  # use a locally mocked SQS server endpoint instead of AWS
  Shoryuken::Client.sqs.config[:endpoint]=URI('http://localhost:4100')
end

Shoryuken.configure_server do |config|

  # register all shoryuken middleware
  config.server_middleware do |chain|
    chain.add JobMonitoringMiddleware
    chain.add JobPrometheusMetricMiddleware
    chain.add JobRavenReporterMiddleware
    chain.add JobRequestStoreMiddleware
  end
end
