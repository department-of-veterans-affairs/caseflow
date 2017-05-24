class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  force_ssl if: :ssl_enabled?
  before_action :check_out_of_service
  before_action :strict_transport_security

  before_action :set_timezone,
                :setup_fakes,
                :check_whats_new_cookie
  before_action :set_raven_user
  before_action :verify_authentication

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from VBMS::ClientError, with: :on_vbms_error

  def unauthorized
    render status: 403
  end

  private

  def check_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("out_of_service")
  end

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def not_found
    respond_to do |format|
      format.html do
        render "errors/404", layout: "application", status: 404
      end
      format.json do
        render json: {
          errors: ["Response not found"] }, status: 404
      end
    end
  end

  def current_user
    @current_user ||= begin
      user = User.from_session(session, request)
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

  def help_url
    {
      "certification" => certification_help_path,
      "dispatch-arc" => dispatch_help_path,
      "reader" => reader_help_path,
      "hearings" => hearings_help_path
    }[application] || help_path
  end
  helper_method :help_url

  # Link used when clicking logo
  def logo_path
    root_path
  end
  helper_method :logo_path

  def certification_header(title)
    "&nbsp &gt &nbsp".html_safe + title
  end
  helper_method :certification_header

  def set_raven_user
    if current_user && ENV["SENTRY_DSN"]
      # Raven sends error info to Sentry.
      Raven.user_context(
        email: current_user.email,
        css_id: current_user.css_id,
        regional_office: current_user.regional_office
      )
    end
  end

  def set_timezone
    Time.zone = current_user.timezone if current_user
  end

  # This is used in development mode to:
  # - Ensure the fakes are loaded (reset in dev mode on file save & class reload)
  # - Setup the default authenticated user
  def setup_fakes
    Fakes::Initializer.setup!(Rails.env)
  end

  def test_user?
    !Rails.deploy_env?(:prod) && current_user.css_id.include?(ENV["TEST_USER_ID"])
  end
  helper_method :test_user?

  def check_whats_new_cookie
    client_last_seen_version = cookies[:whats_new]
    @show_whats_new_indicator = client_last_seen_version.nil? ||
                                client_last_seen_version != WhatsNewService.version
  end

  def verify_authentication
    return true if current_user && current_user.authenticated?

    session["return_to"] = request.original_url
    redirect_to login_path
  end

  def page_title(title)
    "&nbsp &#124 &nbsp".html_safe + title
  end
  helper_method :page_title

  def verify_feature_enabled(feature)
    return true if FeatureToggle.enabled?(feature, user: current_user)
    Rails.logger.info("User id #{current_user.id} attempted to access #{feature} "\
                      " feature but it was not enabled for them #{request.original_url}")
    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_authorized_roles(*roles)
    return true if current_user && roles.all? { |r| current_user.can?(r) }
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

  def on_vbms_error
    respond_to do |format|
      format.html do
        @error_title = "VBMS Failure"
        @error_subtitle = "Unable to communicate with the VBMS system at this time."
        @error_retry_external_service = "VBMS"
        render "errors/500", layout: "application", status: 500
      end

      format.json do
        render json: { errors: [:vbms_error] }, status: 500
      end
    end
  end

  def feedback_url
    # :nocov:
    unless ENV["CASEFLOW_FEEDBACK_URL"]
      return "https://vaww.vaco.portal.va.gov/sites/BVA/olkm/DigitalService/Lists/Feedback/NewForm.aspx"
    end
    # :nocov:

    # TODO: when we want to segment feedback subjects further,
    # add more conditions here.
    subject = if request.original_fullpath.include? "dispatch"
                "Caseflow Dispatch"
              elsif request.original_fullpath.include? "certifications"
                "Caseflow Certification"
              elsif request.original_fullpath.include? "reader"
                "Caseflow Reader"
              else
                # default to just plain Caseflow.
                "Caseflow"
              end

    param_object = { redirect: request.original_url, subject: subject }

    ENV["CASEFLOW_FEEDBACK_URL"] + "?" + param_object.to_param
  end
  helper_method :feedback_url

  class << self
    def dependencies_faked?
      Rails.env.development? || Rails.env.test? || Rails.env.demo?
    end
  end
end
