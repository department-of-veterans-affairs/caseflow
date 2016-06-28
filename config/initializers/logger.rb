def get_session(req)
  session_cookie_name = Rails.application.config.session_options[:key]
  req.cookie_jar.encrypted[session_cookie_name] || {}
end

# :nocov:
log_tags = []
log_tags << lambda { |req|
  session = get_session(req)
  username = session["username"]
  nil unless username
  ro = session["regional_office"]
  ro ? "#{username} (#{ro})" : username
}

config = Rails.application.config
config.log_tags = log_tags

# roll logger over every 1MB, retain 10
logger_path = config.paths["log"].first
rollover_logger = Logger.new(logger_path, 10, 1.megabyte)
Rails.logger = ActiveSupport::TaggedLogging.new(rollover_logger) unless Rails.env.development?
# :nocov:
