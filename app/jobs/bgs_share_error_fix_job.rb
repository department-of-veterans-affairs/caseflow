# frozen_string_literal: true

require_relative "../../lib/helpers/master_scheduler_interface.rb"
class BgsShareErrorFixJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "ShareError"
  end

  def perform
    capture_start_time

    clear_hlr_errors if hlrs_with_errors.present?
    clear_rius_errors if rius_with_errors.present?
    clear_bge_errors if bges_with_errors.present?

    @stuck_job_report_service.write_log_report(error_text)
    capture_end_time
    log_processing_time
  end

  def loop_through_and_call_process_records(records)
    @stuck_job_report_service.append_record_count(records.count, error_text)

    records.each do |record|
      epe = find_end_product_establishment(record)
      next if epe.established_at.blank?

      process_records(record)
      @stuck_job_report_service.append_single_record(record.class.name, record.id)
    end

    @stuck_job_report_service.append_record_count(records.count, error_text)
  end

  # :reek:FeatureEnvy
  def process_records(object_type)
    ActiveRecord::Base.transaction do
      object_type.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(object_type.class.name, object_type.id, error)
    end
  end

  def clear_hlr_errors
    loop_through_and_call_process_records(hlrs_with_errors)
  end

  def clear_rius_errors
    loop_through_and_call_process_records(rius_with_errors)
  end

  def clear_bge_errors
    loop_through_and_call_process_records(bges_with_errors)
  end

  def hlrs_with_errors
    HigherLevelReview.where("establishment_error ILIKE?", "%#{error_text}%")
  end

  def rius_with_errors
    RequestIssuesUpdate.where("error ILIKE?", "%#{error_text}%")
  end

  def bges_with_errors
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%#{error_text}%")
  end

  def records_with_errors
    hlrs = hlrs_with_errors
    rius = rius_with_errors
    bges = bges_with_errors

    all_records_with_errors = hlrs + rius + bges

    all_records_with_errors
  end

  def log_processing_time
    (@end_time && @start_time) ? @end_time - @start_time : 0
  end

  def capture_start_time
    @start_time ||= Time.zone.now
  end

  def capture_end_time
    @end_time ||= Time.zone.now
  end

  private

  def find_end_product_establishment(record)
    case record.class.name
    when "RequestIssuesUpdate"
      EndProductEstablishment.find_by(id: record.review_id)
    when "HigherLevelReview"
      EndProductEstablishment.find_by(veteran_file_number: record.veteran_file_number)
    when "BoardGrantEffectuation"
      record.end_product_establishment
    else
      # Handle other record types as needed
    end
  end
end
