# xxx remove
require "net/http"
require "uri"

class HealthChecksController < ActionController::Base
  include TrackRequestId

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def initialize
    #@pushgateway = Caseflow::PushgatewayService.new
    
    # xxx remove
    @health_uri = URI("http://127.0.0.1:9091/-/healthy")
  end

  # xxx remove
  def pushgateway_healthy?
    # see: https://github.com/prometheus/pushgateway/pull/135
    res = Net::HTTP.get_response(@health_uri)
    res.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end

  def healthy?
    # Check health of sidecar services
    if !Rails.deploy_env?(:prod)
      #@pushgateway.healthy?

      # xxx remove
      pushgateway_healthy?
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
