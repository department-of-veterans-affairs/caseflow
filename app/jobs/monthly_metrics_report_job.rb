# frozen_string_literal: true

###
# Monthly stats sent to jobs slack channel. These are manually sent on to OIT.

class MonthlyMetricsReportJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  # number of appeals
  # ClaimReviewAsyncStatsReporter established within 7 days (count + %), plus total,cancelled,processed
  def perform
    @start_date = Time.zone.today.prev_month.at_beginning_of_month
    @end_date = Time.zone.today.prev_month.at_end_of_month.end_of_day

    appeals_this_month = count_appeals_this_month
    async_stats = ClaimReviewAsyncStatsReporter.new(start_date: start_date, end_date: end_date)
    certification_metric = Metrics::CertificationUsage.new(Metrics::DateRange.new(start_date, end_date))

    send_report(appeals: appeals_this_month, async_stats: async_stats, certification_metric: certification_metric)
  end

  private

  attr_reader :start_date, :end_date

  def count_appeals_this_month
    Appeal.where("established_at >= ? AND established_at <= ?", start_date, end_date).count
  end

  def send_report(appeals:, async_stats:, certification_metric:)
    msg = build_report(appeals, async_stats, certification_metric)
    slack_service.send_notification(msg, self.class.to_s)
  end

  # rubocop:disable Metrics/LineLength
  def build_report(appeals, async_stats, certification_metric)
    certification_paperless_metric = certification_metric.call[:paperless_metric]
    sc_stats = async_stats.stats[:supplemental_claims]
    hlr_stats = async_stats.stats[:higher_level_reviews]

    report = []
    report << "Monthly report #{start_date} to #{end_date.to_date}"
    report << "Percentage of all cases certified with Caseflow: #{certification_paperless_metric}"
    report << "Appeals established within 7 days: #{appeals} (100%)"
    report << "Supplemental Claims within 7 days: #{sc_stats[:established_within_seven_days]} (#{sc_stats[:established_within_seven_days_percent]}%)"
    report << "Higher Level Reviews within 7 days: #{hlr_stats[:established_within_seven_days]} (#{hlr_stats[:established_within_seven_days_percent]}%)"
    report << async_stats.as_csv
    report.join("\n")
  end
  # rubocop:enable Metrics/LineLength
end
