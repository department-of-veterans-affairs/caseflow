# frozen_string_literal: true

class ApplicationController < ApplicationBaseController
  include AuthenticatedControllerAction

  before_action :set_application
  around_action :set_timezone
  before_action :setup_fakes
  before_action :set_raven_user
  before_action :verify_authentication
  before_action :set_paper_trail_whodunnit
  before_action :deny_vso_access, except: [:unauthorized, :feedback]
  before_action :set_no_cache_headers

  rescue_from StandardError do |e|
    fail e unless e.class.method_defined?(:serialize_response)

    # The `actionable` attribute will be shown as part of the Slack message from Sentry
    Raven.capture_exception(e, extra: { error_uuid: error_uuid, actionable: e.try(:actionable),
                                        application: e.try(:application) })
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

  def handle_non_critical_error(endpoint, err)
    Rails.logger.error "#{err.message}\n#{err.backtrace.join("\n")}"

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
      if User.first_time_logging_in?(session)
        flash.now[:show_vha_org_join_info] = true
      end

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
    urls = []
    urls << queue_application_url

    urls << hearing_application_url if current_user.hearings_user?

    manage_urls_for_vha(urls) if current_user.vha_employee?

    # Only return the URL list if the user has applications to switch between
    if urls.length > 1
      return urls.sort_by { |url| url[:sort_order] || url.count + 1 }
    end

    nil
  end
  helper_method :application_urls

  def manage_urls_for_vha(urls)
    urls << case_search_url
    urls << decision_reviews_vha_url
    urls << intake_application_url if current_user.intake_user?
    urls.reject! { |url| url[:title] == "Queue" } if current_user.roles.include?("Case Details")
  end

  def decision_reviews_vha_url
    {
      title: "Decision Review Queue",
      link: "/decision_reviews/vha",
      prefix: "VHA",
      sort_order: 2
    }
  end

  def intake_application_url
    {
      title: "Intake",
      link: "/intake",
      sort_order: 1
    }
  end

  def queue_application_url
    {
      title: "Queue",
      link: "/queue",
      sort_order: 3
    }
  end

  def hearing_application_url
    {
      title: "Hearings",
      link: "/hearings/schedule",
      sort_order: 5
    }
  end

  def case_search_url
    {
      title: "Search cases",
      link: "/search",
      sort_order: 4
    }
  end

  def defult_menu_items
    [
      { title: "Help", link: help_url },
      { title: "Send Feedback", link: feedback_url, target: "_blank" },
      { title: "Release History", link: release_history_url, target: "_blank" }
    ]
  end

  def manage_teams_menu_items
    current_user.administered_teams.map do |team|
      {
        title: "#{team.name} team management",
        link: team.user_admin_path
      }
    end
  end

  def manage_all_teams_menu_item
    {
      title: COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK,
      link: url_for(controller: "/team_management", action: "index")
    }
  end

  def manage_users_menu_item
    {
      title: COPY::USER_MANAGEMENT_PAGE_DROPDOWN_LINK,
      link: url_for(controller: "/user_management", action: "index")
    }
  end

  def admin_menu_items
    admin_urls = []
    admin_urls.concat(manage_teams_menu_items) if current_user&.administered_teams&.any?
    admin_urls.push(manage_users_menu_item) if current_user&.can_view_user_management?
    if current_user&.can_view_team_management? || current_user&.can_view_judge_team_management?
      admin_urls.unshift(manage_all_teams_menu_item)
    end
    admin_urls.flatten
  end

  def dropdown_urls
    urls = defult_menu_items
    urls.concat(admin_menu_items)

    if current_user.present?
      urls.append(title: "Sign Out", link: url_for(controller: "/sessions", action: "destroy"), border: true)
      if ApplicationController.dependencies_faked?
        urls.append(title: "Switch User", link: url_for(controller: "/test/users", action: "index"))
      end
    else
      urls.append(title: "Sign In", link: url_for("/search"), border: true)
    end

    urls
  end
  helper_method :dropdown_urls

  def certification_header(title)
    "&nbsp &gt &nbsp".html_safe + title
  end
  helper_method :certification_header

  def set_no_cache_headers
    no_cache if FeatureToggle.enabled?(:set_no_cache_headers, user: current_user)
  end

  # https://stackoverflow.com/a/748646
  def no_cache
    # :nocov:
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT" # waaaay in the past
    # :nocov:
  end

  def update_poa_information(appeal)
    clear_poa_not_found_cache(appeal)
    cooldown_period = cooldown_period_remaining(appeal)
    byebug
    if cooldown_period > 0
      render json: {
        alert_type: "info",
        message: "Information is current at this time. Please try again in #{cooldown_period} minutes",
        power_of_attorney: power_of_attorney_data
      }
    else
      message, result, status = update_or_delete_power_of_attorney!(appeal)
      render json: {
        alert_type: result,
        message: message,
        power_of_attorney: (status == "updated") ? power_of_attorney_data : {}
      }
    end
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

  # these two methods were previously in appeals controller trying to see if they can be brought here.

  def clear_poa_not_found_cache(appeal)
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.veteran&.file_number}")
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.claimant_participant_id}")
  end

  def cooldown_period_remaining(appeal)
    next_update_allowed_at = appeal.poa_last_synced_at + 10.minutes if appeal.poa_last_synced_at.present?
    if next_update_allowed_at && next_update_allowed_at > Time.zone.now
      return ((next_update_allowed_at - Time.zone.now) / 60).ceil
    end

    0
    # 1 # this needs to be changed back to 0
  end

  def update_or_delete_power_of_attorney!(appeal)
    appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!) # clear memoization on legacy appeals
    poa = appeal.bgs_power_of_attorney

    if poa.blank?
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "blank"]
    elsif poa.bgs_record == :not_found
      poa.destroy!
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "deleted"]
    else
      poa.save_with_updated_bgs_record!
      ["POA Updated Successfully", "success", "updated"]
    end
  rescue StandardError => error
    [error, "error", "error"]
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
