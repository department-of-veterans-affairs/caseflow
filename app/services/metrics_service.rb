# frozen_string_literal: true

require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  # rubocop:disable Metrics/MethodLength
  def self.record(description, service: nil, name: "unknown")
    return_value = nil
    app = RequestStore[:application] || "other"
    service ||= app

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      metric = PrometheusService.send("#{service}_request_latency".to_sym)

      latency = stopwatch.real
      metric.set({ app: app, name: name }, latency)
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
  rescue StandardError
    if service
      metric = PrometheusService.send("#{service}_request_error_counter".to_sym)
      metric.increment(app: app, name: name)
      increment_datadog_counter("request_error", service, name, app)
    end

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    if service
      metric = PrometheusService.send("#{service}_request_attempt_counter".to_sym)
      metric.increment(app: app, name: name)
      increment_datadog_counter("request_attempt", service, name, app)
    end
  end
  # rubocop:enable Metrics/MethodLength

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
