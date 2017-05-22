class Api::V1::ApplicationController < ActionController::Base
  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  before_action :setup_fakes

  private

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
