# frozen_string_literal: true

class ClaimDateDtFixJob < CaseflowJob

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
  end

  def perform
    capture_start_time

    loop_through_and_call_process_records

    capture_end_time
    log_processing_time
  end

  def error_text
    "ClaimDateDt"
  end

  def loop_through_and_call_process_records
    return if records_with_errors.blank?

    stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    records_with_errors.each do |single_decision_document|
      next unless valid_decision_document?(single_decision_document)

      process_records(single_decision_document)
    end

    stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    stuck_job_report_service.write_log_report(error_text)
  end

  def valid_decision_document?(decision_document)
    decision_document.processed_at.present? &&
      decision_document.uploaded_to_vbms_at.present?
  end

  # :reek:FeatureEnvy
  def process_records(decision_document)
    ActiveRecord::Base.transaction do
      decision_document.clear_error!
    rescue StandardError => error
      log_error(error)
      stuck_job_report_service.append_errors(decision_document.class.name, decision_document.id, error)
    end
  end

  def records_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{error_text}%")
  end

  def log_processing_time
    (@end_time && @start_time) ? @end_time - @start_time : 0
  end

  def capture_start_time
    @start_time ||= Time.zone.now
  end

  def capture_end_time
    @end_time ||= Time.zone.now
  end
end
