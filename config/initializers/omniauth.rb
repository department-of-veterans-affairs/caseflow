if ENV.has_key?('SSOI_SAML_XML_LOCATION') && ENV.has_key?('SSOI_SAML_PRIVATE_KEY_LOCATION')
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva, 'CASEFLOW', ENV['SSOI_SAML_PRIVATE_KEY_LOCATION'], ENV['SSOI_SAML_XML_LOCATION'],
             :callback_path => '/auth/saml_callback',
             :path_prefix => '/auth'
  end
end