# frozen_string_literal: true

class SystemEncounteredUnknownErrorJob < CaseflowJob
  ERROR_TEXT = "The system has encountered an unknown error"

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform
    loop_through_and_call_process_records
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

  def handle_decision_document_without_epe(decision_document)
    ActiveRecord::Base.transaction do
      upload_document_to_vbms(decision_document)
      @stuck_job_report_service.append_single_record(decision_document.class.name, decision_document.id)
      decision_document.clear_error!
    end
  end

  def loop_through_and_call_process_records
    return if decision_docs_with_errors.blank?

    @stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      if valid_decision_document?(single_decision_document)
        process_records(single_decision_document)
      else
        @stuck_job_report_service.logs.push("This Decision Document with the ID of #{single_decision_document.id} is invalid.")
      end
    end

    @stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)
    @stuck_job_report_service.write_log_report(ERROR_TEXT)
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
      @stuck_job_report_service.logs.push("This Decision Document with the ID of #{decision_document.id} has invalid End Product Establishments.")
    end
  rescue StandardError => error
    log_error(error)
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

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
