# frozen_string_literal: true

class UnknownUserFixJob < CaseflowJob
  ERROR_TEXT = "UnknownUser"

  def perform(date = "2023-08-07")
    date = date.to_s
    pattern = /^\d{4}-\d{2}-\d{2}$/
    # return puts "incorrect date format" if !date&.match?(pattern)

    if !date&.match?(pattern)
      puts "incorrect date format, use \"YYYY-mm-dd\""
      return
    end

    date = Time.zone.parse(date)
    return if rius_with_errors.blank?

    stuck_job_report_service = StuckJobReportService.new
    stuck_job_report_service.append_record_count(rius_with_errors.count, ERROR_TEXT)

    rius_with_errors.each do |single_riu|
      next if single_riu.created_at > date

      stuck_job_report_service.append_single_record(single_riu.class.name, single_riu.id)

      ActiveRecord::Base.transaction do
        single_riu.clear_error!
      rescue StandardError => error
        log_error(error)
        stuck_job_report_service.append_errors(single_riu.class.name, single_riu.id, error)
      end
    end
  end

  def rius_with_errors
    RequestIssuesUpdate.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
