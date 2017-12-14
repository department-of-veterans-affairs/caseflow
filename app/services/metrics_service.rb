require "benchmark"
require "dogapi"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  # rubocop:disable Metrics/MethodLength
  def self.record(description, service: nil, name: "unknown")
    return_value = nil
    app = RequestStore[:application] || "other"

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      metric = PrometheusService.send("#{service}_request_latency".to_sym)

      latency = stopwatch.real
      metric.set({ app: app, name: name }, latency)
      emit_datadog_point("request_latency", latency, service, name, app)

    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue
    if service
      metric = PrometheusService.send("#{service}_request_error_counter".to_sym)
      metric.increment(app: app, name: name)
      emit_datadog_point("request_error", 1, service, name, app)
    end

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    if service
      metric = PrometheusService.send("#{service}_request_attempt_counter".to_sym)
      metric.increment(app: app, name: name)
      emit_datadog_point("request_attempt", 1, service, name, app)
    end
  end

  private_class_method def self.emit_datadog_point(metric_name, metric_value, _service, endpoint_name, app_name)
    DataDogService.emit_datadog_point(
      metric_group: "service",
      metric_name: metric_name,
      metric_value: metric_value,
      app_name: app_name,
      attrs: {
        endpoint: endpoint_name
      }
    )
  end
end
