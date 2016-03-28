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

Rails.application.config.log_tags = log_tags

# roll logger over every 1MB, retain 10
config.logger = Logger.new(config.paths["log"].first, 10, 1.megabyte) unless Rails.env.development?
