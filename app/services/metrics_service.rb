require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.timer(description, service: nil, name: "unknown")
    return_value = nil
    app = RequestStore[:application] || "other"

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      metric = PrometheusService.send("#{service}_request_latency".to_sym)

      metric.set({ app: app, name: name }, stopwatch.real)

    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue
    if service
      metric = PrometheusService.send("#{service}_request_error_counter".to_sym)
      metric.increment(app: app, name: name)
    end

    raise
  ensure
    if service
      metric = PrometheusService.send("#{service}_request_attempt_counter".to_sym)
      metric.increment(app: app, name: name)
    end
  end
end
