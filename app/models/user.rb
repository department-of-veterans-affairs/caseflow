class User
  def initialize(args = {})
    @session = args[:session] || {}
  end

  def username
    if User.ssoi_authentication_enabled?
      @session[:username]
    else
      User.authentication_service.ssoi_username
    end
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
    !username.blank?
  end

  def authenticate(regional_office:, password:)
    if User.authenticate_vacols(regional_office, password)
      @session[:regional_office] = regional_office
    end
  end

  def authenticate_ssoi(auth_hash)
    # self.username = auth_hash['uid']
  end

  def return_to=(path)
    @session[:return_to] = path
  end

  def return_to
    @session[:return_to]
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
  end
end

class AuthenticationService
  def self.authenticate_vacols(_regional_office, _passsword)
    true
  end

  def self.ssoi_authentication_enabled?
    false
  end

  def self.ssoi_username
    "TESTMODE"
  end
end
