# frozen_string_literal: true

class SystemEncounteredUnknownErrorJob < CaseflowJob
  ERROR_TEXT = "The system has encountered an unknown error"

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
  end

  def perform
    process_decision_documents
  end

  def process_decision_documents
    return if decision_docs_with_errors.blank?

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)
    decision_docs_with_errors.each do |single_decision_document|
      next unless valid_decision_document?(single_decision_document)

      process_decision_document(single_decision_document)
    end

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def valid_decision_document?(decision_document)
    decision_document.processed_at.present? &&
      decision_document.uploaded_to_vbms_at.present?
  end

  def process_decision_document(decision_document)
    ActiveRecord::Base.transaction do
      dd_epe = decision_document.end_product_establishments
      if dd_epe.empty?
        ExternalApi::VBMSService.upload_document_to_vbms(decision_document.appeal, decision_document)
      end
      dd_epe.each do |single_epe|
        if single_epe.established_at.present? && single_epe.reference_id.present?
          decision_document.clear_error!
        end
      end
    rescue StandardError => error
      log_error(error)
      stuck_job_report_service.append_error(decision_document.class.name, decision_document.id, error)
    end
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
