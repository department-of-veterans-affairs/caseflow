require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.timer(description)
    return_value = nil
    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end
    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  end
end
