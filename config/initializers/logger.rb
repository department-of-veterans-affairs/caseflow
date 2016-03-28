def get_session(req)
  session_cookie_name = Rails.application.config.session_options[:key]
  req.cookie_jar.encrypted[session_cookie_name] || {}
end

log_tags = []
log_tags << lambda { |req|
  session = get_session(req)
  username = session["username"]
  nil unless username
  ro = session["regional_office"]
  ro ? "#{username} (#{ro})" : username
}

# :nocov:
config = Rails.application.config
config.log_tags = log_tags

# roll logger over every 1MB, retain 10
logger_path = config.paths["log"].first
config.logger = Logger.new(logger_path, 10, 1.megabyte) unless Rails.env.development?
# :nocov: