# set up default exponential backoff parameters
ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
  .shoryuken_options(retry_intervals: [3.seconds, 1.minute, 5.minutes, 30.minutes, 1.hour, 4.hours])

Shoryuken.configure_server do |config|
  # placeholder for shoryuken server middleware
end
