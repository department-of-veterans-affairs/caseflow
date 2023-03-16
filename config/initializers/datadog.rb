unless Rails.env.test?
  Datadog.configure do |c|
    options = { analytics_enabled: true }

    c.tracing.analytics.enabled = true
    c.tracing.instrument :rails
    c.tracing.instrument :active_record
    c.tracing.instrument :rack
    c.tracing.instrument :redis, service_name: 'cache'
    c.tracing.instrument :shoryuken

    c.env = ENV['DEPLOY_ENV']
  end
end
