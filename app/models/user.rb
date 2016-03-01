class User
  def initialize(args = {})
    @session = args[:session] || {}
  end

  def username
    @session[:username]
  end

  def first_name
    @session[:first_name]
  end

  def last_name
    @session[:last_name]
  end

  def regional_office
    @session[:regional_office]
  end

  def display_name
    if username
      "#{username} (#{regional_office})"
    else
      regional_office.to_s
    end
  end

  def authenticated?
    !regional_office.blank? && ssoi_authenticated?
  end

  def ssoi_authenticated?
    # authenticated when disabled
    !User.ssoi_authentication_enabled? or !username.blank?
  end

  def authenticate(regional_office:, password:)
    if User.authenticate_vacols(regional_office, password)
      @session[:regional_office] = regional_office

      # do dummy ssoi init
      if not User.ssoi_authentication_enabled?
        ssoi_attributes.keys.each do |key|
          @session[key] = User.authentication_service.public_send("ssoi_#{key}")
        end
      end
    end
  end

  def authenticate_ssoi(auth_hash)
    return false if not auth_hash.has_key? "uid"

    ssoi_attributes.each do |key, value|
      @session[key] = auth_hash[value] if auth_hash[value]
    end

    true
  end

  def unauthenticate
    @session[:regional_office] = nil
    ssoi_attributes.keys.each do |key|
      @session[:key] = nil
    end
  end

  def return_to=(path)
    @session[:return_to] = path
  end

  def return_to
    @session[:return_to]
  end

  private

  def ssoi_attributes
    {:username => "uid", :first_name => "first_name", :last_name => "last_name"}
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, :ssoi_authentication_enabled?, to: :authentication_service

    def from_session(session)
      new(session: session)
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end

    def ssoi_authentication_url
      "/auth/samlva"
    end
  end
end

class AuthenticationService
  def self.authenticate_vacols(_regional_office, _passsword)
    true
  end

  def self.ssoi_authentication_enabled?
    has_xml = ENV.has_key?('SSOI_SAML_XML_LOCATION')
    has_key = ENV.has_key?('SSOI_SAML_PRIVATE_KEY_LOCATION')
    has_xml && has_key
  end

  def self.ssoi_username
    "TESTMODE"
  end

  def self.ssoi_first_name
    "Joe"
  end

  def self.ssoi_last_name
    "Tester"
  end
end