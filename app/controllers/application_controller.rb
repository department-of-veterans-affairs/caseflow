# frozen_string_literal: true

class ApplicationController < ApplicationBaseController
  before_action :set_application
  around_action :set_timezone
  before_action :setup_fakes
  before_action :set_raven_user
  before_action :verify_authentication
  before_action :set_paper_trail_whodunnit
  before_action :deny_vso_access, except: [:unauthorized, :feedback]
  before_action :no_cache

  rescue_from StandardError do |e|
    fail e unless e.class.method_defined?(:serialize_response)

    Raven.capture_exception(e, extra: { error_uuid: error_uuid })
    render(e.serialize_response)
  end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from BGS::ShareError, VBMS::ClientError, with: :on_external_error

  rescue_from Caseflow::Error::VacolsRepositoryError do |e|
    Rails.logger.error "Vacols error occured: #{e.message}"
    Raven.capture_exception(e, extra: { error_uuid: error_uuid })
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { "errors": ["title": e.class.to_s, "detail": e.message] }, status: :bad_request
    end
  end

  private

  def deny_non_bva_admins
    redirect_to "/unauthorized" unless Bva.singleton.user_has_access?(current_user)
  end

  def manage_teams_menu_items
    current_user.administered_teams.map do |team|
      {
        title: "#{team.name} team management",
        link: team.user_admin_path
      }
    end
  end

  def admin_menu_items
    [
      {
        title: COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK,
        link: url_for(controller: "/team_management", action: "index")
      }, {
        title: COPY::USER_MANAGEMENT_PAGE_DROPDOWN_LINK,
        link: url_for(controller: "/user_management", action: "index")
      }
    ]
  end

  def handle_non_critical_error(endpoint, err)
    error_type = err.class.name
    if !err.class.method_defined? :serialize_response
      code = (err.class == ActiveRecord::RecordNotFound) ? 404 : 500
      err = Caseflow::Error::SerializableError.new(code: code, message: err.to_s)
    end

    DataDogService.increment_counter(
      metric_group: "errors",
      metric_name: "non_critical",
      app_name: RequestStore[:application],
      attrs: {
        endpoint: endpoint,
        error_type: error_type,
        error_code: err.code
      }
    )

    render err.serialize_response
  end

  def current_user
    @current_user ||= begin
      user = User.from_session(session)
      RequestStore.store[:current_user] = user
      user
    end
  end
  helper_method :current_user

  def feature_enabled?(feature)
    FeatureToggle.enabled?(feature, user: current_user)
  end
  helper_method :feature_enabled?

  def logo_class
    return "cf-logo-image-default" if logo_name.nil?

    "cf-logo-image-#{logo_name.downcase.tr(' ', '-')}"
  end
  helper_method :logo_class

  def logo_name
    nil
  end
  helper_method :logo_name

  def application
    RequestStore.store[:application].to_s.downcase
  end
  helper_method :application

  # Link used when clicking logo
  def logo_path
    root_path
  end
  helper_method :logo_path

  def application_urls
    urls = [{
      title: "Queue",
      link: "/queue"
    }]
    if current_user.hearings_user?
      urls << {
        title: "Hearings",
        link: "/hearings/schedule"
      }
    end

    # Only return the URL list if the user has applications to switch between
    (urls.length > 1) ? urls : nil
  end
  helper_method :application_urls

  def dropdown_urls
    urls = [
      { title: "Help", link: help_url },
      { title: "Send Feedback", link: feedback_url, target: "_blank" },
      { title: "Release History", link: release_history_url, target: "_blank" }
    ]

    urls.concat(manage_teams_menu_items) if current_user&.administered_teams&.any?
    urls.concat(admin_menu_items) if Bva.singleton.user_has_access?(current_user)

    if ApplicationController.dependencies_faked?
      urls.append(title: "Switch User", link: url_for(controller: "/test/users", action: "index"))
    end

    urls.append(title: "Sign Out", link: url_for(controller: "/sessions", action: "destroy"), border: true)

    urls
  end
  helper_method :dropdown_urls

  def certification_header(title)
    "&nbsp &gt &nbsp".html_safe + title
  end
  helper_method :certification_header

  # https://stackoverflow.com/a/748646
  def no_cache
    # :nocov:
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    # :nocov:
  end

  def case_search_home_page
    return false if current_user.admin?
    return false if current_user.organization_queue_user? || current_user.vso_employee?
    return false if current_user.attorney_in_vacols? || current_user.judge_in_vacols?
    return false if current_user.colocated_in_vacols?

    true
  end
  helper_method :case_search_home_page

  def deny_vso_access
    redirect_to "/unauthorized" if current_user&.vso_employee?
  end

  def invalid_record_error(record)
    render json: {
      "errors": ["title": COPY::INVALID_RECORD_ERROR_TITLE, "detail": record.errors.full_messages.join(" ,")]
    }, status: :bad_request
  end

  def required_parameters_missing(array_of_keys)
    render json: {
      "errors": [
        "title": "Missing required parameters",
        "detail": "Required parameters are missing: #{array_of_keys.join(' ,')}"
      ]
    }, status: :bad_request
  end

  def set_raven_user
    if current_user && ENV["SENTRY_DSN"]
      # Raven sends error info to Sentry.
      Raven.user_context(
        email: current_user.email,
        css_id: current_user.css_id,
        station_id: current_user.station_id,
        regional_office: current_user.regional_office
      )
    end
  end

  def set_timezone
    old_time_zone = Time.zone
    Time.zone = session[:timezone] || current_user&.timezone
    session[:timezone] ||= current_user&.timezone
    yield
  ensure
    Time.zone = old_time_zone
  end

  # This is used in development mode to:
  # - Ensure the fakes are loaded (reset in dev mode on file save & class reload)
  # - Setup the default authenticated user
  def setup_fakes
    Fakes::Initializer.setup!(Rails.env)
  end

  def set_application
    RequestStore.store[:application] = "not-set"
  end

  def test_user?
    !Rails.deploy_env?(:prod) && current_user.css_id.include?(ENV["TEST_USER_ID"])
  end
  helper_method :test_user?

  def verify_authentication
    return true if current_user&.authenticated?

    session["return_to"] = request.original_url
    redirect_to login_path
  end

  def page_title(title)
    "&nbsp &#124 &nbsp".html_safe + title
  end
  helper_method :page_title

  # Verifies that the user has any of the roles passed
  def verify_authorized_roles(*roles)
    return true if current_user && roles.any? { |r| current_user.can?(r) }

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  # Verifies the passed user matches the current user
  def verify_user(user)
    return true if current_user == user

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_system_admin
    redirect_to "/unauthorized" unless current_user.admin?
  end

  # Set a flag to say the page has routing managed by React
  # This suppress rails Google Analytics page view events
  def react_routed
    @react_routed = true
  end

  def on_external_error(error)
    unless error.ignorable?
      Raven.capture_exception(error, extra: { error_uuid: error_uuid })
    end

    respond_to do |format|
      flash[:error] = error.body
      format.html do
        render "errors/500", layout: "application", status: :internal_server_error
      end

      format.json do
        render json: { errors: [:external_error], error_uuid: error_uuid }, status: :internal_server_error
      end
    end
  end

  def error_uuid
    @error_uuid ||= SecureRandom.uuid
  end
  helper_method :error_uuid

  def feedback_subject
    feedback_hash = {
      "dispatch" => "Caseflow Dispatch",
      "certifications" => "Caseflow Certification",
      "reader" => "Caseflow Reader",
      "hearings" => "Caseflow Hearings",
      "intake" => "Caseflow Intake",
      "queue" => "Caseflow Queue"
    }
    subject = feedback_hash.keys.select { |route| request.original_fullpath.include?(route) }[0]
    subject.nil? ? "Caseflow" : feedback_hash[subject]
  end

  def feedback_url
    "/feedback"
  end
  helper_method :feedback_url

  def help_url
    {
      "certification" => certification_help_path,
      "dispatch-arc" => dispatch_help_path,
      "reader" => reader_help_path,
      "hearings" => hearing_prep_help_path,
      "intake" => intake_help_path
    }[application] || help_path
  end
  helper_method :help_url

  def release_history_url
    "https://headwayapp.co/va-caseflow-updates"
  end
  helper_method :release_history_url

  def build_date
    return Rails.application.config.build_version[:date] if Rails.application.config.build_version
  end
  helper_method :build_date

  class << self
    def dependencies_faked?
      Rails.env.test? ||
        Rails.env.demo? ||
        Rails.env.ssh_forwarding? ||
        Rails.env.development?
    end
  end
end
