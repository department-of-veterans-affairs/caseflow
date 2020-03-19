# frozen_string_literal: true

class ReportRequestIssuesStatsJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :intake

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = ReportRequestIssuesStatsJob.name.underscore

  def perform
    RequestStore.store[:current_user] = User.system_user
    report_request_issues_stats

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  rescue StandardError => error
    log_error(@start_time, error)
  end

  def report_request_issues_stats
    # TODO
    emit("request_issues_stats", 10)
  end

  def emit(name, value, attrs: {})
    DataDogService.emit_gauge(
      metric_group: METRIC_GROUP_NAME,
      metric_name: name,
      metric_value: value,
      app_name: APP_NAME,
      attrs: attrs
    )
  end

  def log_error(start_time, err)
    duration = time_ago_in_words(start_time)
    msg = "ReportRequestIssuesStatsJob failed after running for #{duration}. Fatal error: #{err.message}"

    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err)

    slack_service.send_notification(msg)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end

  private

  def request_issue_counts_for_appeal_ids(appeal_ids)
    RequestIssue.where(decision_review_id: appeal_ids, decision_review_type: Appeal.name)
      .group(:decision_review_id).count
  end

end
