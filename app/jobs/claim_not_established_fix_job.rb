# frozen_string_literal: true

class ClaimNotEstablishedFixJob < CaseflowJob
  ERROR_TEXT = "Claim not established."
  EPECODES = %w[030 040 930 682].freeze

  def perform
    stuck_job_report_service = StuckJobReportService.new
    return if decision_docs_with_errors.blank?

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      file_number = single_decision_document.veteran.file_number
      epe = EndProductEstablishment.find_by(veteran_file_number: file_number)
      next unless validate_epe(epe)

      stuck_job_report_service.append_single_record(single_decision_document.class.name, single_decision_document.id)

      ActiveRecord::Base.transaction do
        single_decision_document.clear_error!
      rescue StandardError => error
        log_error(error)
        stuck_job_report_service.append_errors(single_decision_document.class.name, single_decision_document.id,
                                               error)
      end
    end

    stuck_job_report_service.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)
    stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end

  def validate_epe(epe)
    epe_code = epe&.code&.slice(0, 3)
    EPECODES.include?(epe_code) && epe&.established_at.present?
  end
end
