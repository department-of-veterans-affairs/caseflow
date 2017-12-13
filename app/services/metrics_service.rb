require "benchmark"
require "dogapi"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  
  @dog = Dogapi::Client.new(ENV["DATADOG_API_KEY"])

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
      self.emit_datadog_point("service_request_latency", latency, service)
      
    end
    
    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue
    if service
      metric = PrometheusService.send("#{service}_request_error_counter".to_sym)
      metric.increment(app: app, name: name)
      self.emit_datadog_point("service_request_error", 1, service)
    end
    
    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric
    raise
  ensure
    if service
      metric = PrometheusService.send("#{service}_request_attempt_counter".to_sym)
      metric.increment(app: app, name: name)
      self.emit_datadog_point("service_request_attempt", 1, service)
    end
  end

  private

  def self.emit_datadog_point(metric_name, metric_value, service)
    @dog.emit_point(metric_name, metric_value, :service => service, :env => Rails.env, :host => `hostname`.strip)
  end    
end
