# frozen_string_literal: true

class ScDtaForAppealFixJob < CaseflowJob
  ERRORTEXT = "Can't create a SC DTA for appeal"

  def records_with_errors
    DecisionDocument.where("error ILIKE ?", "%#{ERRORTEXT}%")
  end

  def sc_dta_for_appeal_fix
    stuck_job_report_service = StuckJobReportService.new
    return if records_with_errors.blank?

    # count of records with errors before fix
    stuck_job_report_service.append_record_count(records_with_errors.count, ERRORTEXT)

    records_with_errors.each do |decision_doc|
      claimant = decision_doc.appeal.claimant

      next unless claimant.payee_code.nil?

      if claimant.type == "VeteranClaimant"
        claimant.update!(payee_code: "00")
      elsif claimant.type == "DependentClaimant"
        claimant.update!(payee_code: "10")
      end
      stuck_job_report_service.append_single_record(decision_doc.class.name, decision_doc.id)
      clear_error_on_record(decision_doc)
    end

    # record count with errors after fix
    stuck_job_report_service.append_record_count(records_with_errors.count, ERRORTEXT)
    stuck_job_report_service.write_log_report(ERRORTEXT)
  end

  def clear_error_on_record(decision_doc)
    ActiveRecord::Base.transaction do
      decision_doc.clear_error!
    rescue StandardError => error
      log_error(error)
      stuck_job_report_service.append_errors(decision_doc.class.name, decision_doc.id, error)
    end
  end
end
