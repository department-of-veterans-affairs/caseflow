class HealthChecksController < ActionController::Base
  protect_from_forgery with: :exception

  def show
    healthcheck = HealthCheck.new
    status = healthcheck.healthy? ? :ok : :bad_request
    body = {
      healthy: healthcheck.healthy?
    }.merge(Rails.application.config.build_version || {})

    render json: body, status: status
  end
end
