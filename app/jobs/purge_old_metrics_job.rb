class PurgeOldMetricsJob < ApplicationJob
  PURGE_END_DATE = "2024-03-12".freeze

  queue_with_priority :low_priority

  def perform
    Metric.where("created_at <= DATE('#{purge_end_date}')").destroy_all
  end

  private

  def purge_end_date
    PURGE_END_DATE
  end
end