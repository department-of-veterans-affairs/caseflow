class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  before_action :set_timezone,
                :setup_fakes,
                :check_whats_new_cookie
  before_action :set_raven_user

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def unauthorized
    render status: 403
  end

  private

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def not_found
    render "errors/404", layout: "application", status: 404
  end

  def current_user
    @current_user ||= User.from_session(session)
  end
  helper_method :current_user

  def logo_class
    "cf-logo-image-default"
  end
  helper_method :logo_class

  def set_raven_user
    if current_user && ENV["SENTRY_DSN"]
      # Raven sends error info to Sentry.
      Raven.user_context(
        email: current_user.username,
        regional_office: current_user.regional_office
      )
    end
  end

  def set_timezone
    Time.zone = current_user.timezone if current_user
  end

  def setup_fakes
    Fakes::Initializer.development! if Rails.env.development? || Rails.env.demo?
  end

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

  def verify_authorized_roles(*roles)
    return true if current_user && roles.all? { |r| current_user.can?(r) }
    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  # Verifies the passed user matches the current user
  def verify_user(user)
    return true if current_user == user

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  class << self
    def dependencies_faked?
      Rails.env.development? || Rails.env.test? || Rails.env.demo?
    end
  end
end
