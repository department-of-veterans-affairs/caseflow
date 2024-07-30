# frozen_string_literal: true

require_relative "../../lib/helpers/master_scheduler_interface.rb"
class NoAvailableModifiersFixJob < CaseflowJob
  include MasterSchedulerInterface

  SPACE = 10

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "NoAvailableModifiers"
  end

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

  def loop_through_and_call_process_records
    veterans_with_errors.each do |vet_fn|
      active_count = current_active_eps_count(vet_fn) || 0

      available_space = SPACE - active_count
      next if available_space <= 0

      supp_claims = supp_claims_on_veteran(vet_fn)
      next if supp_claims.empty?

      process_records(supp_claims, available_space)
    end
  end

  # :reek:FeatureEnvy
  def process_records(supp_claims, available_space)
    supp_claims.each do |sc|
      next if available_space <= 0

      @stuck_job_report_service.append_single_record(sc.class.name, sc.id)
      ActiveRecord::Base.transaction do
        DecisionReviewProcessJob.perform_now(sc)
      rescue StandardError => error
        log_error(error)
        @stuck_job_report_service.append_error(sc.class.name, sc.id, error)
      end
      available_space -= 1
    end
  end

  def supp_claims_on_veteran(file_number)
    records_with_errors.select { |sc| sc.veteran_file_number == file_number }
  end

  def current_active_eps_count(file_number)
    synced_statuses = EndProductEstablishment.where(veteran_file_number: file_number).pluck(:synced_status).compact
    synced_statuses.count { |status| status != "CAN" && status != "CLR" }
  end

  def veterans_with_errors
    records_with_errors.pluck(:veteran_file_number).uniq
  end

  def records_with_errors
    SupplementalClaim.where("establishment_error ILIKE ?", "%#{error_text}%")
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
