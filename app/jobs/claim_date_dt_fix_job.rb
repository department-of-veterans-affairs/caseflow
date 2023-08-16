# frozen_string_literal: true

class ClaimDateDtFixJob < CaseflowJob
  ERROR_TEXT = "ClaimDateDt"

  def perform
    stuck_job_report_service = StuckJobReportService.new

    return if decision_docs_with_errors.blank?

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      return unless single_decision_document.processed_at.present? &&
                    single_decision_document.uploaded_to_vbms_at.present?

      stuck_job_report_service.append_single_record(single_decision_document.class.name, single_decision_document.id)

      ActiveRecord::Base.transaction do
        single_decision_document.clear_error!
      rescue StandardError => error
        log_error(error)
        stuck_job_report_service.append_errors(single_decision_document.class.name, single_decision_document.id, error)
      end
    end

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
