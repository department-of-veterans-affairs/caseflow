require 'ddtrace'

unless Rails.env.test?
  Datadog.configure do |c|
    c.service = "DD_SERVICE"

    c.tracing.enabled = true
    c.tracing.instrument :rails
    c.tracing.instrument :active_record
    c.tracing.instrument :rack
    c.tracing.instrument :redis
    c.tracing.instrument :shoryuken

    c.env = ENV['DEPLOY_ENV']
  end
end
