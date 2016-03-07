require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.timer(description, &block)
    stopwatch = Benchmark.measure(&block)
    Rails.logger.info("#{description}: #{stopwatch}")
  end
end
