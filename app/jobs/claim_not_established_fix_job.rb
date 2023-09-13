# frozen_string_literal: true

class ClaimNotEstablishedFixJob < CaseflowJob
  ERROR_TEXT = "Claim not established."
  EPECODES = %w[030 040 930 682].freeze
  STUCK_JOB_REPORT_SERVICE = StuckJobReportService.new

  def perform
    return if decision_docs_with_errors.blank?

    STUCK_JOB_REPORT_SERVICE.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)

    decision_docs_with_errors.each do |single_decision_document|
      file_number = single_decision_document.veteran.file_number
      epe_array = EndProductEstablishment.where(veteran_file_number: file_number)
      validated_epes = epe_array.map { |epe| validate_epe(epe) }

      STUCK_JOB_REPORT_SERVICE.append_single_record(single_decision_document.class.name, single_decision_document.id)

      resolve_error_on_records(single_decision_document, validated_epes)
    end

    STUCK_JOB_REPORT_SERVICE.append_record_count(decision_docs_with_errors.count, ERROR_TEXT)
    STUCK_JOB_REPORT_SERVICE.write_log_report(ERROR_TEXT)
  end

  def decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end

  def validate_epe(epe)
    epe_code = epe&.code&.slice(0, 3)
    EPECODES.include?(epe_code) && epe&.established_at.present?
  end

  def resolve_error_on_records(object_type, epes_array)
    ActiveRecord::Base.transaction do
      if !epes_array.include?(false)
        object_type.clear_error!
      end
    rescue StandardError => error
      log_error(error)
      STUCK_JOB_REPORT_SERVICE.append_errors(object_type.class.name, object_type.id, error)
    end
  end
end
