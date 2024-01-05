# frozen_string_literal: true
require_relative "../../lib/helpers/master_scheduler_interface.rb"
class ClaimNotEstablishedFixJob < CaseflowJob
  include MasterSchedulerInterface

  EPECODES = %w[030 040 930 682].freeze

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "Claim not established."
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

  def loop_through_and_call_process_records
    records_with_errors.each do |single_decision_document|
      file_number = single_decision_document.veteran.file_number
      epe_array = EndProductEstablishment.where(veteran_file_number: file_number)
      validated_epes = epe_array.map { |epe| validate_epe(epe) }

      @stuck_job_report_service.append_single_record(single_decision_document.class.name, single_decision_document.id)

      process_records(single_decision_document, validated_epes)
    end
  end

  def validate_epe(epe)
    epe_code = epe&.code&.slice(0, 3)
    EPECODES.include?(epe_code) && epe&.established_at.present?
  end

  # :reek:FeatureEnvy
  def process_records(object_type, epes_array)
    ActiveRecord::Base.transaction do
      if !epes_array.include?(false)
        object_type.clear_error!
      end
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
    end
  end

  def records_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{error_text}%")
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
