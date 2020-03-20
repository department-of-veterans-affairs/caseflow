# frozen_string_literal: true

class ReportRequestIssuesStatsJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :intake

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = ReportRequestIssuesStatsJob.name.underscore
  METRIC_NAME_PREFIX = "request_issues.unidentified_with_contention"

  def perform
    RequestStore.store[:current_user] = User.system_user
    report_request_issues_stats
  rescue StandardError => error
    log_error(error)
  ensure
    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end

  private

  def emit(name, value, attrs: {})
    DataDogService.emit_gauge(
      metric_group: METRIC_GROUP_NAME,
      metric_name: name,
      metric_value: value,
      app_name: APP_NAME,
      attrs: attrs
    )
  end

  def log_error(err)
    duration = time_ago_in_words(start_time)
    msg = "ReportRequestIssuesStatsJob failed after running for #{duration}. Fatal error: #{err.message}"
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err)

    slack_service.send_notification(msg)
  end

  def report_request_issues_stats
    start_of_month = Time.zone.now.last_month.beginning_of_month
    req_issues = unidentified_request_issues_with_contention(start_of_month, start_of_month.next_month)
    emit(METRIC_NAME_PREFIX, req_issues.count)

    req_issues.group(:closed_status).count.each do |ben_type, count|
      emit("#{METRIC_NAME_PREFIX}.st.#{ben_type || 'nil'}", count)
    end

    req_issues.group(:benefit_type).count.each do |ben_type, count|
      emit("#{METRIC_NAME_PREFIX}.ben.#{ben_type}", count)
    end

    dr_counts_by_type = req_issues.group(:decision_review_type).count
    dr_counts_by_type.each do |dr_type, count|
      emit("#{METRIC_NAME_PREFIX}.dr.#{dr_type}", count)
    end

    # Could use `req_issues.group(:veteran_participant_id).count.count` but there's a count discrepancy
    emit("#{METRIC_NAME_PREFIX}.vet_count",
         req_issues.map(&:decision_review).map(&:veteran_file_number).uniq.count)
  end

  def unidentified_request_issues_with_contention(start_date, end_date)
    RequestIssue.where.not(contention_reference_id: nil)
      .where(is_unidentified: true)
      .where("created_at >= ?", start_date)
      .where("created_at < ?", end_date)
  end
end
