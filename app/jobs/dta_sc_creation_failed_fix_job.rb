# frozen_string_literal: true

class DtaScCreationFailedFixJob < CaseflowJob
  ERROR_TEXT = "DTA SC Creation Failed"

  def perform
    stuck_job_report_service = StuckJobReportService.new
    return if hlrs_with_errors.blank?

    stuck_job_report_service.append_record_count(hlrs_with_errors.count, ERROR_TEXT)

    hlrs_with_errors.each do |hlr|
      next unless SupplementalClaim.find_by(
        decision_review_remanded_id: hlr.id,
        decision_review_remanded_type: "HigherLevelReview"
      )

      stuck_job_report_service.append_single_record(hlr.class.name, hlr.id)

      ActiveRecord::Base.transaction do
        hlr.clear_error!
      rescue StandardError => error
        log_error(error)
        stuck_job_report_service.append_error(hlr.class.name, hlr.id, error)
      end
    end

    stuck_job_report_service.append_record_count(hlrs_with_errors.count, ERROR_TEXT)
    stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def hlrs_with_errors
    HigherLevelReview.where("establishment_error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
