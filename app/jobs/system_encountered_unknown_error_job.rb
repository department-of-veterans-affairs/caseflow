# frozen_string_literal: true

class SystemEncounteredUnknownErrorJob < CaseflowJob
  ERROR_TEXT = "The system has encountered an unknown error"

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
  end

  def perform
    process_decision_documents
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

  # :reek:FeatureEnvy
  def process_decision_document(decision_document)
    dd_epe = decision_document.end_product_establishments

    if dd_epe.empty?
      ActiveRecord::Base.transaction do
        upload_document_to_vbms(decision_document)
        decision_document.clear_error!
      end
    elsif all_epes_valid?(dd_epe)
      decision_document.clear_error!
    end
  rescue StandardError => error
    log_error(decision_document&.id, error)
  end

  def all_epes_valid?(epes)
    valid_epes = epes.map do |single_epe|
      single_epe.established_at.present? && single_epe.reference_id.present?
    end
    !valid_epes.include?(false)
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
