# frozen_string_literal: true

class UnknownUserFixJob < CaseflowJob
  ERROR_TEXT = "UnknownUser"

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def perform(date = "2023-08-07")
    date = date.to_s
    pattern = /^\d{4}-\d{2}-\d{2}$/
    if !date.match?(pattern)
      fail ArgumentError, "Incorrect date format, use 'YYYY-mm-dd'"
    end

    begin
      parsed_date = Time.zone.parse(date)
    rescue ArgumentError => error
      log_error(error)
      raise error
    end
    return if rius_with_errors.blank?

    @stuck_job_report_service.append_record_count(rius_with_errors.count, ERROR_TEXT)
    rius_with_errors.each do |single_riu|
      next if single_riu.created_at.nil? || single_riu.created_at > parsed_date

      @stuck_job_report_service.append_single_record(single_riu.class.name, single_riu.id)

      resolve_error_on_records(single_riu)
    end
    @stuck_job_report_service.append_record_count(rius_with_errors.count, ERROR_TEXT)
    @stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  # :reek:FeatureEnvy
  def resolve_error_on_records(object_type)
    object_type.clear_error!
  rescue StandardError => error
    log_error(error)
    @stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
  end

  def rius_with_errors
    RequestIssuesUpdate.where("error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
