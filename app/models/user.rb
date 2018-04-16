class User < ApplicationRecord
  has_many :tasks
  has_many :document_views
  has_many :appeal_views
  has_many :hearing_views
  has_many :annotations

  BOARD_STATION_ID = "101".freeze

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_writer :regional_office

  FUNCTIONS = ["Establish Claim", "Manage Claim Establishment", "Certify Appeal",
               "Reader", "Hearing Prep", "Mail Intake", "Admin Intake"].freeze

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

  def vacols_uniq_id
    @vacols_uniq_id ||= self.class.user_repository.vacols_uniq_id(css_id)
  end

  def vacols_role
    @vacols_role ||= self.class.user_repository.vacols_role(css_id)
  end

  def vacols_attorney_id
    @vacols_attorney_id ||= self.class.user_repository.vacols_attorney_id(css_id)
  end

  def vacols_group_id
    @vacols_group_id ||= self.class.user_repository.vacols_group_id(css_id)
  end

  def access_to_task?(vacols_id)
    self.class.user_repository.can_access_task?(css_id, vacols_id)
  end

  def ro_is_ambiguous_from_station_office?
    station_offices.is_a?(Array)
  end

  def timezone
    (RegionalOffice::CITIES[regional_office] || {})[:timezone] || "America/Chicago"
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

  def global_admin?
    Functions.granted?("Global Admin", css_id)
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
    tasks.to_complete.find_by(type: task_type.to_s)
  end

  def to_hash
    serializable_hash
  end

  def to_session_hash
    serializable_hash.merge("id" => css_id, "name" => full_name)
  end

  def station_offices
    RegionalOffice::STATIONS[station_id]
  end

  def current_case_assignments_with_views
    appeals = current_case_assignments
    opened_appeals = viewed_appeals(appeals.map(&:id))

    appeal_streams = Appeal.fetch_appeal_streams(appeals)
    appeal_stream_hearings = get_appeal_stream_hearings(appeal_streams)

    appeals.map do |appeal|
      appeal.to_hash(
        viewed: opened_appeals[appeal.id],
        issues: appeal.issues,
        hearings: appeal_stream_hearings[appeal.id]
      )
    end
  end

  def current_case_assignments
    self.class.appeal_repository.load_user_case_assignments_from_vacols(css_id)
  end

  private

  def get_appeal_stream_hearings(appeal_streams)
    appeal_streams.reduce({}) do |acc, (appeal_id, appeals)|
      acc[appeal_id] = appeal_hearings(appeals.map(&:id))
      acc
    end
  end

  def viewed_appeals(appeal_ids)
    appeal_views.where(appeal_id: appeal_ids).each_with_object({}) do |appeal_view, object|
      object[appeal_view.appeal_id] = true
    end
  end

  def appeal_hearings(appeal_ids)
    Hearing.where(appeal_id: appeal_ids)
  end

  class << self
    attr_writer :appeal_repository
    attr_writer :user_repository
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    # Empty method used for testing purposes (required)
    def clear_current_user; end

    def system_user
      new(
        station_id: "283",
        css_id: Rails.deploy_env?(:prod) ? "CSFLOW" : "CASEFLOW1"
      )
    end

    def from_session(session)
      user = session["user"] ||= authentication_service.default_user_session

      return nil if user.nil?

      find_or_create_by(css_id: user["id"], station_id: user["station_id"]).tap do |u|
        u.full_name = user["name"]
        u.email = user["email"]
        u.roles = user["roles"]
        u.regional_office = session[:regional_office]
        u.save
      end
    end

    def create_from_vacols(css_id:, station_id:, full_name:)
      User.find_or_initialize_by(css_id: css_id, station_id: station_id).tap do |user|
        # When we create a user from VACOLS, check to see if the user already exists
        # CSS names are more accurate than VACOLS
        user.full_name = full_name
        user.save! if user.new_record?
      end
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end

    def appeal_repository
      @appeal_repository ||= AppealRepository
    end

    def user_repository
      @user_repository ||= UserRepository
    end
  end
end
