# frozen_string_literal: true

class CalculateDispatchStatsJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :dispatch

  # :nocov:
  def perform
    DispatchStats.throttled_calculate_all!
  end
  # :nocov:
end
