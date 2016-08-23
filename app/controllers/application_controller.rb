class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  before_action :set_timezone,
                :setup_fakes,
                :check_whats_new_cookie

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def unauthorized
    render status: 403
  end

  # @param ga_event A hash containing :eventCategory (required), :eventLabel, :eventValue. See
  # https://developers.google.com/analytics/devguides/collection/analyticsjs/events for full details.
  def push_ga_event(ga_event)
    @ga_events ||= []
    ga_event[:hitType] = "event"
    ArgumentError.new("eventCategory required") if ga_event[:eventCategory].nil?
    @ga_events << ga_event
  end

  private

  def ssl_enabled?
    Rails.env.production?
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

  def set_timezone
    Time.zone = current_user.timezone
  end

  def setup_fakes
    Fakes::Initializer.development! if Rails.env.development?
  end

  def check_whats_new_cookie
    client_last_seen_version = cookies[:whats_new]
    @show_whats_new_indicator = client_last_seen_version.nil? ||
                                client_last_seen_version != WhatsNewService.version
  end

  def verify_authentication
    return true if current_user.authenticated?

    current_user.return_to = request.original_url
    redirect_to login_path
  end
end
