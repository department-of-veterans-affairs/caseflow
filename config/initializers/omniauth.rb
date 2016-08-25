require 'omniauth/strategies/saml/validation_error'

ENV_SAML_XML = 'SSOI_SAML_XML_LOCATION'
ENV_SAML_KEY = 'SSOI_SAML_PRIVATE_KEY_LOCATION'
ENV_SAML_CRT = 'SSOI_SAML_CERTIFICATE_LOCATION'

Rails.application.config.ssoi_login_path = "/auth/samlva"

def ssoi_authentication_enabled?
  # never disable in production
  return true if Rails.env.production?

  # detect SAML files
  return ENV.has_key?(ENV_SAML_XML) && ENV.has_key?(ENV_SAML_KEY) && ENV.has_key?(ENV_SAML_CRT)
end

# :nocov:
if ssoi_authentication_enabled?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      'https://dev.caseflow.ds.va.gov/auth',
      ENV[ENV_SAML_KEY],
      ENV[ENV_SAML_CRT],
      ENV[ENV_SAML_XML],
      false,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  end
else
  require 'fakes/test_auth_strategy'

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :test_auth_strategy,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      request_path: Rails.application.config.ssoi_login_path
  end
end
# :nocov:
