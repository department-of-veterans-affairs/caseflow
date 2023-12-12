# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  attr_accessor :start_time

  before_perform do |job|
    job.start_time = Time.zone.now
  end

  # Automatically report runtime to MetricsService if job does not explicitly report to MetricsService.
  # Note: This block is not called if an error occurs when `perform` is executed --
  # see https://stackoverflow.com/questions/50263787/does-active-job-call-after-perform-when-perform-raises-an-error
  after_perform do |job|
    metrics_service_report_runtime(metric_group_name: job.class.name.underscore) unless @reported_to_metrics_service
  end

  def metrics_service_report_runtime(metric_group_name:)
    MetricsService.record_runtime(
      app_name: "caseflow_job",
      metric_group: metric_group_name,
      start_time: @start_time
    )
    @reported_to_metrics_service = true
  end

  def metrics_service_report_time_segment(segment:, start_time:)
    job_duration_seconds = Time.zone.now - start_time

    MetricsService.emit_gauge(
      app_name: "caseflow_job_segment",
      metric_group: segment,
      metric_name: "runtime",
      metric_value: job_duration_seconds
    )
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end

  def log_error(error, extra: {})
    Rails.logger.error(error)
    Rails.logger.error(error.backtrace.join("\n"))
    capture_exception(error: error, extra: extra)
  end
end
