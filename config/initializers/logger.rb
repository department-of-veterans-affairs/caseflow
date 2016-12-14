def get_session(req)
  session_cookie_name = Rails.application.config.session_options[:key]
  req.cookie_jar.encrypted[session_cookie_name] || {}
end

# :nocov:
ip = Rails.env.production? ? IPSocket.getaddress(Socket.gethostname) : 'localhost'
logged_in_user = lambda { |req|
  session = get_session(req)
  username = session["user"] ? session["user"]["id"] : session["username"]
  nil unless username
  ro = session["regional_office"]
  ro ? "#{username} (#{ro})" : username
}

log_tags = [:host, ip, logged_in_user]

config = Rails.application.config
config.log_tags = log_tags
# :nocov: