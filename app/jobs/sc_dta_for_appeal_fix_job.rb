# frozen_string_literal: true

class ScDtaForAppealFixJob < CaseflowJob
  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "Can't create a SC DTA for appeal"
  end

  def perform
    start_time
    return if records_with_errors.blank?

    # count of records with errors before fix
    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    loop_through_and_call_process_records

    # record count with errors after fix
    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
    @stuck_job_report_service.write_log_report(error_text)
    end_time
    log_processing_time
  end

  def loop_through_and_call_process_records
    records_with_errors.each do |decision_doc|
      claimant = decision_doc.appeal.claimant

      next unless claimant.payee_code.nil?

      if claimant.type == "VeteranClaimant"
        claimant.update!(payee_code: "00")
      elsif claimant.type == "DependentClaimant"
        claimant.update!(payee_code: "10")
      end
      @stuck_job_report_service.append_single_record(decision_doc.class.name, decision_doc.id)
      process_records(decision_doc)
    end
  end

  # :reek:FeatureEnvy
  def process_records(decision_doc)
    ActiveRecord::Base.transaction do
      decision_doc.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(decision_doc.class.name, decision_doc.id, error)
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
