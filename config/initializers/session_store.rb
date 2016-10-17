# Be sure to restart your server when you modify this file.
options = {
  key: '_caseflow_session',
  secure: Rails.env.production?,
  expire_after: 24.hours
}

if ENV["DEPLOY_ENV"]
  options[:domain] = :all
  options[:tld_length] = (ENV["DEPLOY_ENV"] == "prod") ? 4 : 5
end

# Convert to this when IAM is removed
# options[:domain] = ENV["COOKIE_DOMAIN"] if ENV["COOKIE_DOMAIN"]

Rails.application.config.session_store :cookie_store, options
