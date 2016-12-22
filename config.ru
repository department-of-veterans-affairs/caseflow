# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/client/rack/collector"
require "prometheus/client/rack/exporter"

# use gzip for the '/metrics' route, since it can get big.
use Rack::Deflater,
    if: -> (env, _status, _headers, _body) { env["PATH_INFO"] == "/metrics" }

# traces all HTTP requests
use Prometheus::Client::Rack::Collector

# exposes a metrics HTTP endpoint to be scraped by a prometheus server
use Prometheus::Client::Rack::Exporter

run Rails.application
