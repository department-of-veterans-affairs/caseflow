class User < ActiveRecord::Base
  has_many :tasks
  has_many :document_views
  has_many :appeal_views
  has_many :annotations

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_accessor :ip_address
  attr_writer :regional_office

  FUNCTIONS = ["Establish Claim", "Manage Claim Establishment", "Certify Appeal",
               "Reader", "Hearing Prep"].freeze

  # Because of the function character limit, we need to also alias some functions
  FUNCTION_ALIASES = {
    "Manage Claims Establishme" => ["Manage Claim Establishment"],
    "Hearing Prep" => ["Reader"]
  }.freeze

  def username
    css_id
  end

  def roles
    (self[:roles] || []).inject([]) do |result, role|
      result.concat([role]).concat(FUNCTION_ALIASES[role] ? FUNCTION_ALIASES[role] : [])
    end
  end

  # If RO is ambiguous from station_office, use the user-defined RO. Otherwise, use the unambigous RO.
  def regional_office
    upcase = ->(str) { str ? str.upcase : str }

    ro_is_ambiguous_from_station_office? ? upcase.call(@regional_office) : station_offices
  end

  def ro_is_ambiguous_from_station_office?
    station_offices.is_a?(Array)
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

  # We should not use user.can?("System Admin"), but user.admin? instead
  def can?(thing)
    return true if admin?
    # Check if user is granted the function
    return true if granted?(thing)
    # Check if user is denied the function
    return false if denied?(thing)
    # Ignore "System Admin" function from CSUM/CSEM users
    return false if thing.include?("System Admin")
    roles.include?(thing)
  end

  def admin?
    Functions.granted?("System Admin", css_id)
  end

  def granted?(thing)
    Functions.granted?(thing, css_id)
  end

  def denied?(thing)
    Functions.denied?(thing, css_id)
  end

  def authenticated?
    !regional_office.blank?
  end

  def attributes
    super.merge(display_name: display_name)
  end

  def current_task(task_type)
    tasks.to_complete.find_by(type: task_type)
  end

  def to_hash
    serializable_hash
  end

  def station_offices
    VACOLS::RegionalOffice::STATIONS[station_id]
  end

  def current_case_assignments_with_views
    appeals = current_case_assignments(fetch_issues: true)
    opened_appeals = viewed_appeals(appeals.map(&:id))

    appeals.map do |appeal|
      appeal.to_hash(viewed: opened_appeals[appeal.id])
    end
  end

  def current_case_assignments(fetch_issues = false)
    self.class.appeal_repository.load_user_case_assignments_from_vacols(css_id, fetch_issues)
  end

  private

  def viewed_appeals(appeal_ids)
    appeal_views.where(appeal_id: appeal_ids).each_with_object({}) do |appeal_view, object|
      object[appeal_view.appeal_id] = true
    end
  end

  class << self
    attr_writer :appeal_repository
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    # Empty method used for testing purposes
    def before_set_user
    end

    def system_user(ip_address)
      new(
        station_id: "283",
        css_id: Rails.deploy_env?(:prod) ? "CSFLOW" : "CASEFLOW1",
        ip_address: ip_address
      )
    end

    def from_session(session, request)
      user = session["user"] ||= authentication_service.default_user_session

      return nil if user.nil?

      find_or_create_by(css_id: user["id"], station_id: user["station_id"]).tap do |u|
        u.full_name = user["name"]
        u.email = user["email"]
        u.roles = user["roles"]
        u.ip_address = request.remote_ip
        u.regional_office = session[:regional_office]
        u.save
      end
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end

    def appeal_repository
      @case_assignment_repository ||= AppealRepository
    end
  end
end
