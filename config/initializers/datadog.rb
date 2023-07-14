unless Rails.env.test?
  Datadog.configure do |c|
    # options = { analytics_enabled: true }

    # c.analytics_enabled = true
    # c.use :rails, options
    # c.use :active_record, options
    # c.use :rack, options
    # c.use :redis, options
    # c.use :shoryuken, options

    # c.env = ENV['DEPLOY_ENV']
  end
end
