class CalculateIntakeStatsJob < ApplicationJob
  queue_as :low_priority

  # :nocov:
  def perform
    IntakeStats.throttled_calculate_all!
  end
  # :nocov:
end
