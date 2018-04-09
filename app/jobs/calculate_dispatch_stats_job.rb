class CalculateDispatchStatsJob < ApplicationJob
  queue_as :low_priority

  # :nocov:
  def perform
    DispatchStats.throttled_calculate_all!
  end
  # :nocov:
end
