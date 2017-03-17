require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.timer(description, service: nil, name: "unknown")
    return_value = nil
    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      metric = PrometheusService.send("#{serivce}_request_latency".to_sym)
      app = RequestStore[:application] || "other"

      metric.set({ app: app, name: name }, stopwatch)

    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  end
end
