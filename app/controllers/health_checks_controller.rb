class HealthChecksController < BaseController
  newrelic_ignore_apdex

  def show
    healthcheck = HealthCheck.new
    status = healthcheck.healthy? ? :ok : :bad_request
    body = {
      healthy: healthcheck.healthy?
    }.merge(Rails.application.config.build_version || {})

    render json: body, status: status
  end
end
