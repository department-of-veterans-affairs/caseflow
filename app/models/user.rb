# frozen_string_literal: true

class User < CaseflowRecord # rubocop:disable Metrics/ClassLength
  include BgsService

  has_many :dispatch_tasks, class_name: "Dispatch::Task"
  has_many :document_views
  has_many :appeal_views
  has_many :hearing_views
  has_many :hearings
  has_many :annotations
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :organizations, through: :organizations_users
  has_many :messages
  has_many :unrecognized_appellants, foreign_key: :created_by_id
  has_one :vacols_user, class_name: "CachedUser", foreign_key: :sdomainid, primary_key: :css_id

  # Alternative: where("roles @> ARRAY[?]::varchar[]", role)
  scope :with_role, ->(role) { where("? = ANY(roles)", role) }

  BOARD_STATION_ID = "101"
  LAST_LOGIN_PRECISION = 5.minutes

  # Ephemeral values obtained from CSS on auth. Stored in user's session
  attr_writer :regional_office

  # Because of the function character limit, we need to also alias some functions
  FUNCTION_ALIASES = {
    "Manage Claims Establishme" => ["Manage Claim Establishment"],
    "Hearing Prep" => ["Reader"]
  }.freeze

  before_create :normalize_css_id

  enum status: {
    Constants.USER_STATUSES.active.to_sym => Constants.USER_STATUSES.active,
    Constants.USER_STATUSES.inactive.to_sym => Constants.USER_STATUSES.inactive
  }

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

  def users_regional_office
    selected_regional_office || regional_office
  end

  def acting_judge_in_vacols?
    attorney_in_vacols? && judge_in_vacols?
  end

  def attorney_in_vacols?
    vacols_roles.include?("attorney")
  end

  # Using "pure_judge" terminology from VACOLS::Staff
  # This implementation relies on UserRepository#roles_based_on_staff_fields return values
  def pure_judge_in_vacols?
    vacols_roles.first == "judge"
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

  def hearings_user?
    can_any_of_these_roles?(["Build HearSched", "Edit HearSched", "RO ViewHearSched", "VSO", "Hearing Prep"])
  end

  def can_assign_hearing_schedule?
    can_any_of_these_roles?(["Edit HearSched", "Build HearSched"])
  end

  def can_view_hearing_schedule?
    can?("RO ViewHearSched") && !can?("Build HearSched") && !can?("Edit HearSched")
  end

  def can_view_edit_nod_date?
    ClerkOfTheBoard.singleton.users.include?(self) && FeatureToggle.enabled?(:edit_nod_date, user: self)
  end

  def can_vso_hearing_schedule?
    can?("VSO") && !can?("RO ViewHearSched") && !can?("Build HearSched") && !can?("Edit HearSched")
  end

  def in_hearing_or_transcription_organization?
    HearingsManagement.singleton.users.include?(self) || TranscriptionTeam.singleton.users.include?(self)
  end

  def can_withdraw_issues?
    CaseReview.singleton.users.include?(self) || %w[NWQ VACO].exclude?(regional_office)
  end

  def can_edit_issues?
    CaseReview.singleton.users.include?(self) || can_intake_appeals?
  end

  def can_edit_cavc_remands?
    CavcLitigationSupport.singleton.admins.include?(self)
  end

  def can_intake_appeals?
    BvaIntake.singleton.users.include?(self)
  end

  def administer_org_users?
    admin? || granted?("Admin Intake") || roles.include?("Admin Intake") || member_of_organization?(Bva.singleton)
  end

  def can_view_overtime_status?
    (attorney_in_vacols? || judge_in_vacols?) && FeatureToggle.enabled?(:overtime_revamp, user: self)
  end

  def can_change_hearing_request_type?
    can?("Build HearSched") || can?("Edit HearSched")
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
    if appeal.is_a?(LegacyAppeal)
      fail_if_no_access_to_legacy_task!(appeal.vacols_id)
    else
      appeal.tasks.includes(:assigned_to).any? do |task|
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

  def can_any_of_these_roles?(roles)
    roles.any? { |role| can?(role) }
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
    organizations.any?
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
    skip_attrs = %w[full_name created_at updated_at last_login_at]
    serializable_hash.merge("id" => css_id, "name" => full_name, "pg_user_id" => id).except(*skip_attrs)
  end

  def station_offices
    RegionalOffice::STATIONS[station_id]
  end

  def current_case_assignments
    self.class.appeal_repository.load_user_case_assignments_from_vacols(css_id)
  end

  def administered_teams
    organizations_users.admin.map(&:organization).compact
  end

  def administered_judge_teams
    administered_teams.select { |team| team.is_a?(JudgeTeam) }
  end

  def non_administered_judge_teams
    organizations_users.non_admin.where(organization: JudgeTeam.all)
  end

  def security_profile
    BGSService.new.get_security_profile(
      username: css_id,
      station_id: station_id
    )
  rescue BGS::ShareError, BGS::PublicError
    {}
  end

  def job_title
    security_profile.dig(:job_title)
  end

  def can_intake_decision_reviews?
    !job_title.include?("Senior Veterans Service Representative")
  end

  def user_info_for_idt
    self.class.user_repository.user_info_for_idt(css_id)
  end

  def selectable_organizations
    orgs = organizations.select(&:selectable_in_queue?)
    judge_team_judges = judge? ? [self] : []
    judge_team_judges |= administered_judge_teams.map(&:judge) if FeatureToggle.enabled?(:judge_admin_scm)

    judge_team_judges.each do |judge|
      orgs << {
        name: "Assign #{judge.css_id}",
        url: "/queue/#{judge.css_id}/assign"
      }
    end

    orgs
  end

  def member_of_organization?(org)
    organizations.include?(org)
  end

  def judge?
    !!JudgeTeam.for_judge(self) || judge_in_vacols?
  end

  def attorney?
    non_administered_judge_teams.any? || attorney_in_vacols?
  end

  def update_status!(new_status)
    transaction do
      if new_status.eql?(Constants.USER_STATUSES.inactive)
        user_inactivation
      elsif new_status.eql?(Constants.USER_STATUSES.active)
        user_reactivation
      end

      update!(status: new_status, status_updated_at: Time.zone.now)
    end
  end

  def use_task_pages_api?
    FeatureToggle.enabled?(:user_queue_pagination, user: self)
  end

  def queue_tabs
    # acting VLJs are both judge_in_vacols and attorney_in_vacols and should see the attorney columns
    if (judge_in_vacols? && !attorney_in_vacols?) && !FeatureToggle.enabled?(:judge_queue_tabs, user: self)
      [assigned_tasks_tab]
    else
      [
        assigned_tasks_tab,
        on_hold_tasks_tab,
        completed_tasks_tab
      ]
    end
  end

  def self.default_active_tab
    Constants.QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME
  end

  def assigned_tasks_tab
    ::AssignedTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def on_hold_tasks_tab
    ::OnHoldTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def completed_tasks_tab
    ::CompletedTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def can_act_on_behalf_of_judges?
    member_of_organization?(SpecialCaseMovementTeam.singleton)
  end

  def can_view_team_management?
    member_of_organization?(Bva.singleton)
  end

  def can_view_judge_team_management?
    DvcTeam.for_dvc(self).present?
  end

  def can_view_user_management?
    member_of_organization?(Bva.singleton)
  end

  def show_regional_office_in_queue?
    HearingsManagement.singleton.user_has_access?(self)
  end

  def can_be_assigned_legacy_tasks?
    judge_in_vacols? || attorney_in_vacols?
  end

  def show_reader_link_column?
    false
  end

  private

  def inactive_judge_team
    JudgeTeam.unscoped.inactive.find_by(id: organizations_users.admin.pluck(:organization_id))
  end

  def user_reactivation
    # We do not automatically re-add organization membership for reactivated users
    inactive_judge_team&.active!
  end

  def user_inactivation
    remove_user_from_orgs
    JudgeTeam.for_judge(self)&.inactive!
  end

  def remove_user_from_orgs
    removal_orgs = organizations
    my_judge_team = JudgeTeam.for_judge(self)
    removal_orgs.each do |org|
      OrganizationsUser.remove_user_from_organization(self, org) unless org == my_judge_team
    end
  end

  def normalize_css_id
    self.css_id = css_id.upcase
  end

  def user_info
    @user_info ||= self.class.user_repository.user_info_from_vacols(css_id)
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

      sdomainid = ["BVA", first_name.first, last_name].join
      VACOLS::Staff.create(snamef: first_name, snamel: last_name, sdomainid: sdomainid, sattyid: vlj_id)
    end
    # :nocov:

    def system_user
      @system_user ||= begin
        private_method_name = "#{Rails.current_env}_system_user".to_sym
        send(private_method_name)
      end
    end

    def api_user
      @api_user ||= find_or_create_by(
        station_id: "101",
        css_id: "APIUSER",
        full_name: "API User"
      )
    end

    def from_session(session)
      user_session = session["user"] ||= authentication_service.default_user_session

      return nil if user_session.nil?

      pg_user_id = user_session["pg_user_id"]
      css_id = user_session["id"]
      user_by_id = find_by_pg_user_id!(pg_user_id, session)
      user = user_by_id || find_by_css_id(css_id)

      attrs = attrs_from_session(session, user_session)

      user ||= create!(attrs.merge(css_id: css_id.upcase))
      now = Time.zone.now
      attrs[:last_login_at] = now if !user.last_login_at || now - user.last_login_at > LAST_LOGIN_PRECISION
      user.update!(attrs)
      user_session["pg_user_id"] = user.id
      user
    end

    def find_by_css_id_or_create_with_default_station_id(css_id)
      find_by_css_id(css_id) || User.create(css_id: css_id.upcase, station_id: BOARD_STATION_ID)
    end

    def batch_find_by_css_id_or_create_with_default_station_id(css_ids)
      normalized_css_ids = css_ids.map(&:upcase)
      new_user_css_ids = normalized_css_ids - User.where(css_id: normalized_css_ids).pluck(:css_id)
      User.create(new_user_css_ids.map { |css_id| { css_id: css_id, station_id: User::BOARD_STATION_ID } })
      User.where(css_id: normalized_css_ids)
    end

    def find_by_vacols_username(vacols_username)
      User.joins(:vacols_user).find_by(cached_user_attributes: { slogid: vacols_username })
    end

    def list_hearing_coordinators
      HearingsManagement.singleton.users
    end

    # case-insensitive search
    def find_by_css_id(css_id)
      # this query uses the index_users_unique_css_id
      # find_by(css_id: css_id) does a slower seq scan
      find_by("UPPER(css_id)=UPPER(?)", css_id)
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

    private

    def find_by_pg_user_id!(pg_user_id, session)
      user_by_id = find_by(id: pg_user_id)
      if !user_by_id && pg_user_id
        session["user"]["pg_user_id"] = nil
      end
      user_by_id
    end

    def attrs_from_session(session, user_session)
      {
        station_id: user_session["station_id"],
        full_name: user_session["name"],
        email: user_session["email"],
        roles: user_session["roles"],
        regional_office: session[:regional_office]
      }
    end

    def prod_system_user
      find_or_initialize_by(station_id: "283", css_id: "CSFLOW")
    end

    alias preprod_system_user prod_system_user

    def uat_system_user
      find_or_initialize_by(station_id: "317", css_id: "CASEFLOW1")
    end

    alias test_system_user uat_system_user
    alias development_system_user uat_system_user
  end
end
