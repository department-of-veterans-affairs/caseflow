# frozen_string_literal: true

class Api::ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  include TrackRequestId

  before_action :strict_transport_security

  before_action :setup_fakes,
                :verify_authentication_token,
                :set_api_user

  rescue_from StandardError do |error|
    Raven.capture_exception(error, extra: raven_extra_context)

    render json: {
      "errors": [
        "status": "500",
        "title": "Unknown error occured",
        "detail": "#{error} (Sentry event id: #{Raven.last_event_id})"
      ]
    }, status: :internal_server_error
  end

  rescue_from BGS::ShareError, VBMS::ClientError, with: :on_external_error

  private

  def raven_extra_context
    {}
  end

  # For API calls, we use the system user to make all BGS calls
  def set_api_user
    RequestStore.store[:current_user] = User.system_user
  end

  def verify_authentication_token
    return unauthorized unless api_key

    Rails.logger.info("API authenticated by #{api_key.consumer_name}")
  end

  def api_key
    @api_key ||= authenticate_with_http_token { |token, _options| ApiKey.authorize(token) }
  end

  def unauthorized
    render json: { status: "unauthorized" }, status: :unauthorized
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

  def on_external_error(error)
    if error.ignorable?
      Rails.logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
      upstream_transient_error
    else
      Raven.capture_exception(error)
      upstream_known_error(error)
    end
  end

  def upstream_transient_error
    render json: {
      "errors": [
        "status": "503",
        "title": "Service unavailable",
        "detail": "Upstream service timed out or unavailable to process the request"
      ]
    }, status: :service_unavailable
  end

  def upstream_known_error(error)
    render json: {
      "errors": [
        "status": error.code,
        "title": "Bad request",
        "detail": error.body
      ]
    }, status: error.code || :bad_request
  end
end
