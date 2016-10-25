class User
  def initialize(args = {})
    @session = args[:session] || {}
  end

  def username
    @session["user"] && @session["user"]["id"]
  end

  # If RO is unambiguous from station_office, use that RO. Otherwise, use user defined RO
  def regional_office
    station_offices.is_a?(String) ? station_offices : @session[:regional_office]
  end

  def roles
    @session["user"] && @session["user"]["roles"]
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

  private

  def station_offices
    VACOLS::RegionalOffice::STATIONS[@session["user"] && @session["user"]["station_id"]]
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    def from_session(session)
      session["user"] ||= authentication_service.default_user_session

      return nil if session["user"].nil?

      new(session: session)
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end
  end
end
