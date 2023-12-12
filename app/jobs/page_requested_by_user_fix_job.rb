# frozen_string_literal: true

class PageRequestedByUserFixJob < CaseflowJob
  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def perform
    start_time
    return if records_with_errors.blank?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    loop_through_and_call_process_records

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
    @stuck_job_report_service.write_log_report(error_text)
    end_time
    log_processing_time
  end

  def error_text
    "Page requested by the user is unavailable"
  end

  def loop_through_and_call_process_records
    records_with_errors.each do |bge|
      next if bge.end_product_establishment.nil? || bge.end_product_establishment.established_at.blank?

      @stuck_job_report_service.append_single_record(bge.class.name, bge.id)
      process_records(bge)
    end
  end

  # :reek:FeatureEnvy
  def process_records(object_type)
    object_type.clear_error!
  rescue StandardError => error
    log_error(error)
    @stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
  end

  def records_with_errors
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%#{error_text}%")
  end

  def log_processing_time
    (@end_time && @start_time) ? @end_time - @start_time : 0
  end

  def start_time
    @start_time ||= Time.zone.now
  end

  def end_time
    @end_time ||= Time.zone.now
  end
end
