# frozen_string_literal: true

require_relative "../../lib/helpers/master_scheduler_interface.rb"
class UploadTokenFixJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def perform
    RequestStore[:current_user] = User&.system_user
    start_time

    loop_through_and_call_process_records

    @stuck_job_report_service.write_log_report(error_text)
    end_time
    log_processing_time
  end

  def error_text
    "A problem has been detected with the upload token provided"
  end

  def loop_through_and_call_process_records
    return if records_with_errors.empty?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    records_with_errors.each do |decision_doc|
      process_records(decision_doc)
    end
    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
  end

  def process_records(decision_doc)
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
      @stuck_job_report_service.append_error(decision_doc.class.name, decision_doc.id, error)
    end
  end

  # :reek:FeatureEnvy
  def finalize_decision_doc(decision_document)
    ActiveRecord::Base.transaction do
      decision_document.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_error(decision_document.class.name, decision_document.id, error)
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
