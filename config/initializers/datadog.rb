unless Rails.env.test?
  Datadog.configure do |c|
    options = { analytics_enabled: true }

    c.tracing.analytics.enabled = true
    c.tracing.instrument :rails, options
    c.tracing.instrument :active_record, options
    c.tracing.instrument :rack, options
    c.tracing.instrument :redis, options
    c.tracing.instrument :shoryuken, options

    c.env = ENV['DEPLOY_ENV']
  end
end
