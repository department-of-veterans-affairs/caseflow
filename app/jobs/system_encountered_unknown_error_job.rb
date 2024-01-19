require_relative "../../lib/helpers/master_scheduler_interface.rb"
# frozen_string_literal: true

class SystemEncounteredUnknownErrorJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "The system has encountered an unknown error"
  end

  def perform
    start_time

    loop_through_and_call_process_records

    end_time
    log_processing_time
  rescue StandardError => error
    log_error(error)
    raise error
  end

  def upload_document_to_vbms(decision_document)
    ExternalApi::VBMSService.upload_document_to_vbms(decision_document.appeal, decision_document)
  end

  def valid_decision_document?(decision_document)
    decision_document.processed_at.present? && decision_document.uploaded_to_vbms_at.present?
  end

  # :reek:FeatureEnvy
  def handle_decision_document_without_epe(decision_document)
    ActiveRecord::Base.transaction do
      upload_document_to_vbms(decision_document)
      @stuck_job_report_service.append_single_record(decision_document.class.name, decision_document.id)
      decision_document.clear_error!
    end
  end

  def loop_through_and_call_process_records
    return if records_with_errors.blank?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    records_with_errors.each do |single_decision_document|
      if valid_decision_document?(single_decision_document)
        process_records(single_decision_document)
      else
        @stuck_job_report_service.logs.push("This Decision Document with the ID of
          #{single_decision_document.id} is invalid.")
      end
    end

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
    @stuck_job_report_service.write_log_report(error_text)
  end

  # :reek:FeatureEnvy
  def process_records(decision_document)
    dd_epe = decision_document.end_product_establishments
    if dd_epe.empty?
      handle_decision_document_without_epe(decision_document)
    elsif all_epes_valid?(dd_epe)
      @stuck_job_report_service.append_single_record(decision_document.class.name, decision_document.id)
      decision_document.clear_error!
    else
      @stuck_job_report_service.logs.push("This Decision Document with the ID of #{decision_document.id}
        has invalid End Product Establishments.")
    end
  rescue StandardError => error
    log_error(error)
    @stuck_job_report_service.append_errors(decision_document.class.name, decision_document.id, error)
  end

  def all_epes_valid?(epes)
    epes.each do |single_epe|
      if single_epe.established_at.present? && single_epe.reference_id.present?
        next
      else
        return false
      end
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
