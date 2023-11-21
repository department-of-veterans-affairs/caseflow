# frozen_string_literal: true

class UploadTokenFixJob < CaseflowJob
  ERROR_TEXT = "A problem has been detected with the upload token provided"

  attr_reader :stuck_job_report_service, :vbms

  def initialize
    super
    @stuck_job_report_service = StuckJobReportService.new
  end

  def perform
    RequestStore[:current_user] = User.system_user
    return if decision_docs_with_errors.empty?

    decision_docs_with_errors.each do |decision_doc|
      process_decision_document(decision_doc)
    end
  end

  def process_decision_document(decision_doc)
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
