# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/client/rack/collector"
require "prometheus/client/rack/exporter"

# require basic auth for the /metrics route
use MetricsAuth, "metrics" do |username, password|
  # if we mistakenly didn't set a password for this route, disable the route
  password_missing = ENV["METRICS_PASSWORD"].blank?
  password_matches = [username, password] == [ENV["METRICS_USERNAME"], ENV["METRICS_PASSWORD"]]
  password_missing ? false : password_matches
end

# use gzip for the '/metrics' route, since it can get big.
use Rack::Deflater,
    if: -> (env, _status, _headers, _body) { env["PATH_INFO"] == "/metrics" }

# traces all HTTP requests
use Prometheus::Client::Rack::Collector

# exposes a metrics HTTP endpoint to be scraped by a prometheus server
use Prometheus::Client::Rack::Exporter

# log puma stats to stdout
use PumaStatsLogger::Middleware

run Rails.application
