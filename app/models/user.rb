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
    # fully authenticated
    if authenticated?
      "#{username} (#{regional_office})"

    # just SSOI, not yet vacols authenticated
    elsif ssoi_authenticated?
      username.to_s

    # not authenticated at all
    else
      nil
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
    return false if not auth_hash.has_key? "uid"

    ssoi_attributes.each do |key, value|
      @session[key] = auth_hash[value] if auth_hash[value]
    end

    true
  end

  def unauthenticate
    @session.delete(:regional_office)
    ssoi_attributes.keys.each do |key|
      @session.delete(key)
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
end