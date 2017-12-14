require "benchmark"
require "dogapi"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  datadog_api_key = ENV["DATADOG_API_KEY"]
  if datadog_api_key.nil?
    Rails.logger.warn "Env var DATADOG_API_KEY is not set, so DataDog metrics will not be tracked."
    # Setting the API key to an empty string will make tracking requests silently fail, which is what we want.
    datadog_api_key = ""
  end

  @dog = Dogapi::Client.new(datadog_api_key)

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
      emit_datadog_point("request_latency", latency, service)

    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue
    if service
      metric = PrometheusService.send("#{service}_request_error_counter".to_sym)
      metric.increment(app: app, name: name)
      emit_datadog_point("request_error", 1, service)
    end

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric
    raise
  ensure
    if service
      metric = PrometheusService.send("#{service}_request_attempt_counter".to_sym)
      metric.increment(app: app, name: name)
      emit_datadog_point("request_attempt", 1, service)
    end
  end

  private_class_method def self.emit_datadog_point(metric_name, metric_value, service)
    @dog.emit_point("caseflow.service.#{metric_name}", metric_value,
                    host: `hostname`.strip, type: "counter",
                    tags: [
                      "service:#{service}",
                      "env:#{Rails.env}"
                    ])
  end
end
