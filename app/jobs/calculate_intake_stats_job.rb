class CalculateIntakeStatsJob < ActiveJob::Base
  queue_as :low_priority

  # :nocov:
  def perform
    IntakeStats.throttled_recalculate_all!
  end
  # :nocov:
end
