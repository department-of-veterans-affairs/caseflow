class User < ActiveRecord::Base
  has_many :tasks
  has_many :document_views

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_accessor :roles, :ip_address, :admin_roles
  attr_writer :regional_office

  TASK_TYPE_TO_ROLES = {
    EstablishClaim: { employee: "Establish Claim", manager: "Manage Claim Establishment" }
  }.freeze

  FUNCTIONS = ["Establish Claim", "Manage Claim Establishment", "Certify Appeal", "CertificationV2"].freeze

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
    return true if admin? && admin_roles.include?(thing)
    roles.include? thing
  end

  def admin?
    return false if roles.nil?
    roles.include? "System Admin"
  end

  def authenticated?
    !regional_office.blank?
  end

  # This method is used for VACOLS authentication
  def authenticate(regional_office:, password:)
    return false unless User.authenticate_vacols(regional_office, password)

    @regional_office = regional_office.upcase
  end

  def attributes
    super.merge(display_name: display_name)
  end

  def functions
    User::FUNCTIONS.each_with_object({}) do |function, result|
      result[function] ||= {}
      result[function][:enabled] = admin_roles.include?(function)
    end
  end

  def toggle_admin_roles(role:, enable: true)
    return if role == "System Admin"
    enable ? admin_roles << role : admin_roles.delete(role)
  end

  private

  def station_offices
    VACOLS::RegionalOffice::STATIONS[station_id]
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    # Empty method used for testing purposes
    def before_set_user
    end

    def from_session(session, request)
      user = session["user"] ||= authentication_service.default_user_session

      return nil if user.nil?

      user["admin_roles"] ||= user["roles"] && user["roles"].include?("System Admin") ? ["System Admin"] : []

      find_or_create_by(css_id: user["id"], station_id: user["station_id"]).tap do |u|
        u.full_name = user["name"]
        u.email = user["email"]
        u.roles = user["roles"]
        u.ip_address = request.remote_ip
        u.admin_roles = user["admin_roles"]
        u.regional_office = session[:regional_office]
        u.save
      end
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end
  end
end
