class HealthChecksController < ActionController::Base
  include TrackRequestId

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def is_healthy?
    # Check health of sidecar services
    if not Rails.deploy_env?(:prod)
      Caseflow::PushgatewayService.is_healthy?
    else
      true
    end
  end

  def show
    self.is_healthy?

    # TODO: wire check into controller
    healthy = true

    body = {
      healthy: healthy
    }.merge(Rails.application.config.build_version || {})
    render(json: body, status: healthy ? :ok : :service_unavailable)
  end
end
