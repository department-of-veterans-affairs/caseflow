class CalculateIntakeStatsJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    IntakeStats.throttled_recalculate_all!
  end
end
