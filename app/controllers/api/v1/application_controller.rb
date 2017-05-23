class Api::V1::ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  before_action :setup_fakes,
                :verify_authentication_token

  private

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

  def not_found
    render json: { status: "not found" }, status: 404
  end

  def ssl_enabled?
    Rails.env.production?
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def setup_fakes
    Fakes::Initializer.setup!
  end
end
