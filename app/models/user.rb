class User < ApplicationRecord
  has_many :dispatch_tasks, class_name: "Dispatch::Task"
  has_many :document_views
  has_many :appeal_views
  has_many :hearing_views
  has_many :hearings
  has_many :annotations
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :organizations, through: :organizations_users

  BOARD_STATION_ID = "101".freeze

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_writer :regional_office

  FUNCTIONS = ["Establish Claim", "Manage Claim Establishment", "Certify Appeal",
               "Reader", "Hearing Prep", "Mail Intake", "Admin Intake",
               "Hearing Schedule"].freeze

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
      result.concat([role]).concat(FUNCTION_ALIASES[role] || [])
    end
  end

  # If RO is ambiguous from station_office, use the user-defined RO. Otherwise, use the unambigous RO.
  def regional_office
    upcase = ->(str) { str ? str.upcase : str }

    ro_is_ambiguous_from_station_office? ? upcase.call(@regional_office) : station_offices
  end

  def attorney_in_vacols?
    vacols_roles.include?("attorney")
  end

  def judge_in_vacols?
    vacols_roles.include?("judge")
  end

  def colocated_in_vacols?
    vacols_roles.include?("colocated")
  end

  def dispatch_user_in_vacols?
    vacols_roles.include?("dispatch")
  end

  def intake_user?
    roles && (roles.include?("Mail Intake") || roles.include?("Admin Intake"))
  end

  def administer_org_users?
    admin? || granted?("Admin Intake") || roles.include?("Admin Intake")
  end

  def vacols_uniq_id
    @vacols_uniq_id ||= user_info[:uniq_id]
  end

  def vacols_roles
    @vacols_roles ||= user_info[:roles] || []
  end

  def vacols_attorney_id
    @vacols_attorney_id ||= user_info[:attorney_id]
  end

  def vacols_group_id
    @vacols_group_id ||= user_info[:group_id]
  end

  def vacols_full_name
    @vacols_full_name ||= user_info[:full_name]
  rescue Caseflow::Error::UserRepositoryError
    nil
  end

  def can_edit_request_issues?(appeal)
    Task.where(
      appeal: appeal,
      assigned_to: self,
      status: [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    ).select { |t| t.is_a?(JudgeTask) || t.is_a?(AttorneyTask) }.any?
  end

  def participant_id
    @participant_id ||= bgs.get_participant_id_for_user(self)
  end

  def vsos_user_represents
    @vsos_user_represents ||= bgs.fetch_poas_by_participant_id(participant_id)
  end

  def fail_if_no_access_to_legacy_task!(vacols_id)
    self.class.user_repository.fail_if_no_access_to_task!(css_id, vacols_id)
  end

  def appeal_has_task_assigned_to_user?(appeal)
    if appeal.class.name == "LegacyAppeal"
      fail_if_no_access_to_legacy_task!(appeal.vacols_id)
    else
      appeal.tasks.any? do |task|
        task.assigned_to == self
      end
    end
  end

  def ro_is_ambiguous_from_station_office?
    station_offices.is_a?(Array)
  end

  def timezone
    (RegionalOffice::CITIES[regional_office] || {})[:timezone] || "America/Chicago"
  end

  # If user has never logged in, we might not have their full name in Caseflow DB.
  # So if we do not yet have the full name saved in Caseflow's DB, then
  # we want to fetch it from VACOLS, save it to the DB, then return it
  def full_name
    super || begin
      update(full_name: vacols_full_name) if persisted?
      super
    end
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

  def vso_employee?
    roles.include?("VSO")
  end

  def organization_queue_user?
    FeatureToggle.enabled?(:organization_queue, user: self)
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
    dispatch_tasks.to_complete.find_by(type: task_type.to_s)
  end

  def to_hash
    serializable_hash
  end

  def to_session_hash
    serializable_hash.merge("id" => css_id, "name" => full_name).except("full_name")
  end

  def station_offices
    RegionalOffice::STATIONS[station_id]
  end

  def current_case_assignments_with_views
    appeals = current_case_assignments
    opened_appeals = viewed_appeals(appeals.map(&:id))

    appeal_streams = LegacyAppeal.fetch_appeal_streams(appeals)
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

  def administered_teams
    organizations_users.select(&:admin?).map(&:organization)
  end

  def user_info_for_idt
    self.class.user_repository.user_info_for_idt(css_id)
  end

  def selectable_organizations
    organizations.select(&:selectable_in_queue?)
  end

  private

  def bgs
    @bgs ||= BGSService.new
  end

  def user_info
    @user_info ||= self.class.user_repository.user_info_from_vacols(css_id)
  end

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
    LegacyHearing.where(appeal_id: appeal_ids)
  end

  class << self
    attr_writer :authentication_service
    delegate :authenticate_vacols, to: :authentication_service

    # Empty method used for testing purposes (required)
    def clear_current_user; end

    def css_ids_by_vlj_ids(vlj_ids)
      UserRepository.css_ids_by_vlj_ids(vlj_ids)
    end

    # This method is only used in dev/demo mode to test the judge spreadsheet functionality in hearing scheduling
    # :nocov:
    def create_judge_in_vacols(first_name, last_name, vlj_id)
      return unless Rails.env.development? || Rails.env.demo?

      UserRepository.create_judge_in_vacols(first_name, last_name, vlj_id)
    end
    # :nocov:

    def system_user
      @system_user ||= find_or_initialize_by(
        station_id: Rails.deploy_env?(:prod) ? "283" : "317",
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

    def find_by_css_id_or_create_with_default_station_id(css_id)
      User.find_by(css_id: css_id) || User.create(css_id: css_id, station_id: BOARD_STATION_ID)
    end

    def list_hearing_coordinators
      Rails.cache.fetch("#{Rails.env}_list_of_hearing_coordinators_from_vacols") do
        user_repository.find_all_hearing_coordinators
      end
    end

    def authentication_service
      @authentication_service ||= AuthenticationService
    end

    def appeal_repository
      AppealRepository
    end

    def user_repository
      UserRepository
    end
  end
end
