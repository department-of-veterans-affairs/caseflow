class User
  def initialize(args = {})
    @session = args[:session] || {}
  end

  def username
    @session[:username] || @session["user"]["id"]
  end

  def css?
    @session["user"]
  end

  def regional_office
    @session[:regional_office]
  end

  def roles
    @session["user"]["roles"]
  end

  def timezone
    (VACOLS::RegionalOffice::CITIES[regional_office] || {})[:timezone] || "America/Chicago"
  end

  def display_name
    # fully authenticated
    if authenticated?
      "#{username} (#{regional_office})"

    # just SSOI, not yet vacols authenticated
    else
      username.to_s
    end
  end

  def can?(thing)
    return true unless css?
    return false if roles.nil?
    return true if roles.include? "System Admin"
    roles.include? thing
  end

  def authenticated?
    !regional_office.blank?
  end

  def authenticate(regional_office:, password:)
    return false unless User.authenticate_vacols(regional_office, password)

    @session[:regional_office] = regional_office.upcase
  end

  def authenticate_ssoi(auth_hash)
    return false unless auth_hash.key? "uid"

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

  private

  def ssoi_attributes
    { username: "uid", first_name: "first_name", last_name: "last_name" }
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, :ssoi_authentication_enabled?, to: :authentication_service

    def from_session(session)
      return nil if !session[:username] && session["user"].nil?

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
