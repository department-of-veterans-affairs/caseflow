# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/client/rack/collector"
require "prometheus/client/rack/exporter"

require_relative "app/middleware/metrics_collector"

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

# Collects custom Caseflow metrics
use MetricsCollector

# traces all HTTP requests
use Prometheus::Client::Rack::Collector

# exposes a metrics HTTP endpoint to be scraped by a prometheus server
use Prometheus::Client::Rack::Exporter

# rubocop:disable all
# TODO (alex): this should be a temporary addition to try to solve
# a deployment bug. We should refactor or remove this
# after it serves its purpose. Just a quick fix.
module PumaThreadLogger
  def initialize *args
    Thread.new do
      loop do
        sleep 5

        thread_count = 0
        backlog = 0
        waiting = 0

        # Safely access the thread information.
        # Note that this might slow down performance.
        @mutex.synchronize {
          thread_count = @workers.size
          backlog = @todo.size
          waiting = @waiting
        }

        thread_metric = PrometheusService.app_server_threads
        thread_metric.set({ type: 'idle' }, waiting)
        thread_metric.set({ type: 'active' }, thread_count - waiting)

        # For some reason, even a single Puma server (not clustered) has two booted ThreadPools.
        # One of them is empty, and the other is actually doing work.
        # The check above ignores the empty one.
        if thread_count > 0
          # It might be cool if we knew the Puma worker index for this worker,
          # but that didn't look easy to me.
          # I'm not 100% confident of the right way to measure this,
          # so I added a few.
          msg = "Puma stats -- Process pid: #{Process.pid} "\
           "Total threads: #{thread_count} "\
           "Backlog of actions: #{backlog} "\
           "Waiting threads: #{waiting} "\
           "Active threads: #{thread_count - waiting} "\
           "Live threads: #{@workers.select{|x| x.alive?}.size}/#{@workers.size} alive"
          Rails.logger.info(msg)
        end

      end
    end
    super *args
  end
end

if ENV["THREAD_LOGGING"] == "enabled"
  module Puma
    class ThreadPool
      prepend PumaThreadLogger
    end
  end
end
# rubocop:enable all

run Rails.application
