if ENV['SENTRY_DSN']
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.excluded_exceptions += ["Caseflow::Error::DocumentRetrievalError"]
  end
end
