# frozen_string_literal: true

###
# Bi-weekly metrics sent to the AMO slack channel for Claim Reviews

class AMOMetricsReportJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform
    setup_dates
    async_stats = ClaimReviewAsyncStatsReporter.new(start_date: start_date, end_date: end_date)
    send_report(async_stats: async_stats)
  end

  private

  attr_reader :start_date, :end_date

  def setup_dates
    # if today is the first of the month, do the previous entire month.
    # otherwise, just the month-to-date.
    if Time.zone.today == Time.zone.today.at_beginning_of_month
      @start_date = Time.zone.today.prev_month.at_beginning_of_month
      @end_date = Time.zone.yesterday.end_of_day
    else
      @start_date = Time.zone.today.at_beginning_of_month
      @end_date = Time.zone.now.end_of_day
    end
  end

  def send_report(async_stats:)
    msg = build_report(async_stats)
    slack_service.send_notification(msg, self.class.to_s)
  end

  # rubocop:disable Metrics/AbcSize
  def build_report(async_stats)
    sc_stats = async_stats.stats[:supplemental_claims]
    hlr_stats = async_stats.stats[:higher_level_reviews]
    sc_avg = async_stats.seconds_to_hms(sc_stats[:avg].to_i)
    hlr_avg = async_stats.seconds_to_hms(hlr_stats[:avg].to_i)
    sc_med = async_stats.seconds_to_hms(sc_stats[:median].to_i)
    hlr_med = async_stats.seconds_to_hms(hlr_stats[:median].to_i)
    report = []
    report << "AMO metrics report #{start_date} to #{end_date.to_date}"
    report << "Supplemental Claims #{sc_stats[:total]} established, median #{sc_med} average #{sc_avg}"
    report << "Supplemental Claims newly stuck: #{sc_stats[:expired]}"
    report << "Supplemental Claims total stuck: #{SupplementalClaim.expired_without_processing.with_error.count}"
    report << "Higher Level Reviews #{hlr_stats[:total]} established, median #{hlr_med} average #{hlr_avg}"
    report << "Higher Level Reviews newly stuck: #{hlr_stats[:expired]}"
    report << "Higher Level Reviews total stuck: #{HigherLevelReview.expired_without_processing.with_error.count}"
    report << async_stats.as_csv
    report.join("\n")
  end
  # rubocop:enable Metrics/AbcSize
end
