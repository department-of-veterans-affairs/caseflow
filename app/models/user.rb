class User < ActiveRecord::Base
  has_many :tasks

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_accessor :roles
  attr_writer :regional_office

  def username
    css_id
  end

  # If RO is unambiguous from station_office, use that RO. Otherwise, use user defined RO
  def regional_office
    station_offices.is_a?(String) ? station_offices : @regional_office
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

  # This method is used for VACOLS authentication
  def authenticate(regional_office:, password:)
    return false unless User.authenticate_vacols(regional_office, password)

    @regional_office = regional_office.upcase
  end

  private

  def station_offices
    VACOLS::RegionalOffice::STATIONS[station_id]
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    def from_session(session)
      user = session["user"] ||= authentication_service.default_user_session

      return nil if user.nil?

      find_or_create_by(css_id: user["id"], station_id: user["station_id"]).tap do |u|
        u.roles = user["roles"]
        u.regional_office = session[:regional_office]
      end
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end
  end
end
