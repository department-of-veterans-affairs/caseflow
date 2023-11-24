# frozen_string_literal: true

class UploadTokenFixJob < CaseflowJob
  ERROR_TEXT = "A problem has been detected with the upload token provided"

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform
    RequestStore[:current_user] = User.system_user
    return if decision_docs_with_errors.empty?

    @stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    decision_docs_with_errors.each do |decision_doc|
      process_decision_document(decision_doc)
    end
    @stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)
    @stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def process_decision_document(decision_doc)
    @stuck_job_report_service.append_single_record(decision_doc.class.name, decision_doc.id)
    finalize_decision_doc(decision_doc) && return if all_epes_valid?(decision_doc)

    appeal = decision_doc.appeal
    bva = fetch_bva_decisions(appeal, decision_doc.decision_date)

    if bva.empty?
      upload_document(appeal, decision_doc)
    else
      document_present_in_vbms?(bva) ? finalize_decision_doc(decision_doc) : upload_document(appeal, decision_doc)
    end
  end

  def upload_document(appeal, decision_doc)
    ActiveRecord::Base.transaction do
      ExternalApi::VBMSService.upload_document_to_vbms(appeal, decision_doc)
      finalize_decision_doc(decision_doc)
    rescue StandardError => error
      log_error(error)
      stuck_job_report_service.append_error(decision_doc.class.name, decision_doc.id, error)
    end
  end

  # :reek:FeatureEnvy
  def finalize_decision_doc(decision_document)
    ActiveRecord::Base.transaction do
      decision_document.clear_error!
    rescue StandardError => error
      log_error(error)
      stuck_job_report_service.append_error(decision_document.class.name, decision_document.id, error)
    end
  end

  def all_epes_valid?(decision_document)
    epes = EndProductEstablishment.where(source_type: "DecisionDocument", source_id: decision_document.id)
    processed_epes = epes.map { |epe| epe.established_at.present? && epe.reference_id.present? }
    !processed_epes.uniq.include?(false)
  end

  def fetch_bva_decisions(appeal, decision_date)
    docs = ExternalApi::EFolderService.fetch_documents_for(appeal, RequestStore[:current_user])[:documents]
    docs.select do |doc|
      doc.type == "BVA Decision" && doc.received_at == decision_date
    end
  end

  def document_present_in_vbms?(document)
    ExternalApi::VBMSService.fetch_document_file(document).present?
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
