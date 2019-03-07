# frozen_string_literal: true

class CalculateIntakeStatsJob < ApplicationJob
  queue_as :low_priority
  application_attr :intake

  # :nocov:
  def perform
    IntakeStats.throttled_calculate_all!
  end
  # :nocov:
end
