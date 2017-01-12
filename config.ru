# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/client/rack/collector"
require "prometheus/client/rack/exporter"

# require basic auth for the /metrics route
use MetricsAuth, "metrics" do |username, password|
  # if metrics password mistakenly isn't provided
  # for prod or prod-like envs, disable the route
  if Rails.env.production? && ENV["METRICS_PASSWORD"].blank?
    return false
  end
  # ansible passes us an empty string for a blank value,
  # so use .blank? instead of a simple truthy check
  metrics_username = ENV["METRICS_USERNAME"].blank? ? "caseflow" : ENV["METRICS_USERNAME"]
  metrics_password = ENV["METRICS_PASSWORD"].blank? ? "caseflow" : ENV["METRICS_PASSWORD"]
  [username, password] == [metrics_username, metrics_password]
end

# use gzip for the '/metrics' route, since it can get big.
use Rack::Deflater,
    if: -> (env, _status, _headers, _body) { env["PATH_INFO"] == "/metrics" }

# traces all HTTP requests
use Prometheus::Client::Rack::Collector

# exposes a metrics HTTP endpoint to be scraped by a prometheus server
use Prometheus::Client::Rack::Exporter

run Rails.application
