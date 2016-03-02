ENV_SAML_XML = 'SSOI_SAML_XML_LOCATION'
ENV_SAML_KEY = 'SSOI_SAML_PRIVATE_KEY_LOCATION'

Rails.application.config.ssoi_login_path = "/auth/samlva"

def ssoi_authentication_enabled?
  # never disable in production
  return true if Rails.env.production?

  # detect SAML files
  return ENV.has_key?(ENV_SAML_XML) && ENV.has_key?(ENV_SAML_KEY)
end

if ssoi_authentication_enabled?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva, 'CASEFLOW', ENV[ENV_SAML_KEY], ENV[ENV_SAML_XML],
             :callback_path => '/auth/saml_callback',
             :path_prefix => '/auth'
  end
else
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :developer, :callback_path => '/auth/saml_callback',
             :path_prefix => '/auth',
             :request_path => Rails.application.config.ssoi_login_path
  end
end