# frozen_string_literal: true

class HealthChecksController < ActionController::Base
  include TrackRequestId

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def initialize
    @pushgateway = Caseflow::PushgatewayService.new
  end

  def healthy?
    # Check health of sidecar services
    if ENV.include? "ENABLE_PUSHGATEWAY_HEALTHCHECK"
      @pushgateway.healthy?
    else
      true
    end
  end

  def show
    healthy = healthy?
    body = {
      healthy: healthy
    }.merge(Rails.application.config.build_version || {})
    render(json: body, status: healthy ? :ok : :service_unavailable)
  end
end
