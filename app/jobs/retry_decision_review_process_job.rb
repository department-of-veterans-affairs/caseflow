# frozen_string_literal: true

require_relative "../../lib/helpers/retry_decision_review_processes.rb"
require_relative "../../lib/helpers/master_scheduler_interface.rb"

class RetryDecisionReviewProcessJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform
    start_time
    loop_through_and_call_process_records
    end_time
    log_processing_time
  end

  def error_text
    "RetryDecisionReviewProcessJob failure"
  end

  def records_with_errors
    retry_instance.all_records
  end

  def loop_through_and_call_process_records
    process_records
  end

  def process_records
    retry_instance.retry
  end

  def log_processing_time
    (end_time && start_time) ? end_time - start_time : 0
  end

  def start_time
    @start_time ||= Time.zone.now
  end

  def end_time
    @end_time ||= Time.zone.now
  end

  private

  def retry_instance
    @retry_instance ||= RetryDecisionReviewProcesses.new(report_service: @stuck_job_report_service)
  end
end
