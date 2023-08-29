# frozen_string_literal: true

require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.record(description, service: nil, name: "unknown")
    return_value = nil
    app = RequestStore[:application] || "other"
    service ||= app

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      latency = stopwatch.real
      DataDogService.emit_gauge(
        metric_group: "service",
        metric_name: "request_latency",
        metric_value: latency,
        app_name: app,
        attrs: {
          service: service,
          endpoint: name
        }
      )
    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue StandardError => error
    Raven.capture_exception(error)
    increment_datadog_counter("request_error", service, name, app) if service

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    increment_datadog_counter("request_attempt", service, name, app) if service
  end

  private_class_method def self.increment_datadog_counter(metric_name, service, endpoint_name, app_name)
    DataDogService.increment_counter(
      metric_group: "service",
      metric_name: metric_name,
      app_name: app_name,
      attrs: {
        service: service,
        endpoint: endpoint_name
      }
    )
  end
end
