# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/client/rack/collector"
require "prometheus/client/rack/exporter"

# Perform basic auth on the Prometheus /metrics endpoint so that we do not
# expose sensitive data in the open.
class MetricsAuth < Rack::Auth::Basic
  def call(env)
    request = Rack::Request.new(env)
    case request.path

    when '/metrics' # perform auth for /metrics
      super
    else # skip auth otherwise
      @app.call(env)
    end
  end

end

if Rails.env.development? || Rails.env.demo?
  use MetricsAuth, "metrics" do |username, password|
    metrics_username = ENV["METRICS_USERNAME"] || 'caseflow'
    metrics_password = ENV["METRICS_PASSWORD"] || 'caseflow'
    [username, password] == [metrics_username, metrics_password]
  end

  # use gzip for the '/metrics' route, since it can get big.
  use Rack::Deflater,
      if: -> (env, _status, _headers, _body) { env["PATH_INFO"] == "/metrics" }

  # traces all HTTP requests
  use Prometheus::Client::Rack::Collector

  # exposes a metrics HTTP endpoint to be scraped by a prometheus server
  use Prometheus::Client::Rack::Exporter

end

run Rails.application
