# frozen_string_literal: true

class MonthlyMetricsReportJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  # number of appeals
  # ClaimReviewAsyncStatsReporter established within 7 days (count + %), plus total,cancelled,processed
  def perform
    @start_date = Time.zone.today.at_beginning_of_month
    @end_date = Time.zone.today.at_end_of_month

    appeals_this_month = count_appeals_this_month
    async_stats = ClaimReviewAsyncStatsReporter.new(start_date: start_date, end_date: end_date)

    send_report(appeals: appeals_this_month, async_stats: async_stats)
  end

  private

  attr_reader :start_date, :end_date

  def count_appeals_this_month
    Appeal.where("established_at >= ? AND established_at <= ?", start_date, end_date).count
  end

  def send_report(appeals:, async_stats:)
    msg = build_report(appeals, async_stats)
    slack_service.send_notification(msg, self.class)
  end

  def build_report(appeals, async_stats)
    report = []
    report << "Monthly report #{start_date} to #{end_date}"
    report << "Appeals established: #{appeals}"
    report << async_stats.as_csv
    report.join("\n")
  end
end
