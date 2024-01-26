# frozen_string_literal: true

require_relative "../../lib/helpers/master_scheduler_interface.rb"
class DtaScCreationFailedFixJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  # :reek:FeatureEnvy
  def perform
    start_time

    return if records_with_errors.blank?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    loop_through_and_call_process_records

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
    @stuck_job_report_service.write_log_report(error_text)

    end_time
    log_processing_time
  end

  # :reek:FeatureEnvy
  def loop_through_and_call_process_records
    records_with_errors.each do |hlr|
      next unless SupplementalClaim.find_by(
        decision_review_remanded_id: hlr.id,
        decision_review_remanded_type: "HigherLevelReview"
      )

      @stuck_job_report_service.append_single_record(hlr.class.name, hlr.id)

      process_records(hlr)
    end
  end

  # :reek:FeatureEnvy
  def process_records(record)
    ActiveRecord::Base.transaction do
      record.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(record.class.name, record.id, error)
    end
  end

  def error_text
    "DTA SC creation failed"
  end

  def records_with_errors
    HigherLevelReview.where("establishment_error ILIKE ?", "%#{error_text}%")
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
