class Api::V1::ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  before_action :setup_fakes,
                :verify_authentication_token,
                :set_api_user

  rescue_from StandardError do |error|
    Raven.capture_exception(error)

    render json: {
      "errors": [
        "status": "500",
        "title": "Unknown error occured",
        "detail": "#{error} (Sentry event id: #{Raven.last_event_id})"
      ]
    }, status: 500
  end

  private

  # For API calls, we use the system user to make all BGS calls
  def set_api_user
    RequestStore.store[:current_user] = User.system_user(request.remote_ip)
  end

  def verify_authentication_token
    return unauthorized unless api_key

    Rails.logger.info("API authenticated by #{api_key.consumer_name}")
  end

  def api_key
    @api_key ||= authenticate_with_http_token { |token, _options| ApiKey.authorize(token) }
  end

  def unauthorized
    render json: { status: "unauthorized" }, status: 401
  end

  def ssl_enabled?
    Rails.env.production?
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def setup_fakes
    Fakes::Initializer.setup!(Rails.env)
  end
end
