# frozen_string_literal: true

class DtaScCreationFailedFixJob < CaseflowJob
  # include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def error_text
    "DTA SC creation failed"
  end

  # :reek:FeatureEnvy
  def perform
    stuck_job_report_service = StuckJobReportService.new
    return if hlrs_with_errors.blank?

    begin
      return if records_with_errors.blank?

      @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

      loop_through_and_call_process_records

      @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
      @stuck_job_report_service.write_log_report(error_text)

      end_time
      log_processing_time
    rescue StandardError => error
      log_error(error)
      raise error
    end
  end

  def loop_through_and_call_process_records
    begin
      loop_through_and_process_records_for_hlrs_with_errors if hlrs_with_errors.present?
      loop_through_and_process_records_for_appeals_with_errors if appeals_with_errors.present?
    rescue StandardError => error
      log_error(error)
    end
  end

  # Methods for remdiating HLRs with errors

  def loop_through_and_process_records_for_hlrs_with_errors
    hlrs_with_errors.each do |hlr|
      begin
        next unless remanded_hlr?(hlr)

        @stuck_job_report_service.append_single_record(hlr.class.name, hlr.id)
        process_records(hlr)
      rescue StandardError => error
        log_error(error)
      end
    end

    stuck_job_report_service.append_record_count(hlrs_with_errors.count, ERROR_TEXT)
    stuck_job_report_service.write_log_report(ERROR_TEXT)
  end

  def remanded_hlr?(hlr)
    SupplementalClaim.find_by(
      decision_review_remanded_id: hlr.id,
      decision_review_remanded_type: "HigherLevelReview"
    )
  end

  # Methods for remdiating Appeals with errors

  def loop_through_and_process_records_for_appeals_with_errors
    appeals_with_errors.each do |appeal|
      begin
        if valid_appeal?(appeal)
          @stuck_job_report_service.append_single_record(appeal.class.name, appeal.id)
          process_records(appeal)
        end
      rescue StandardError => error
        log_error(error)
      end
    end
  end

  # :reek:FeatureEnvy
  def valid_appeal?(appeal)
    return false unless appeal.established_at

    update_payee_code(appeal.claimant) if appeal.claimant.payee_code.nil?
  end

  # :reek:FeatureEnvy
  def update_payee_code(claimant)
    claimant.update!(payee_code: claimant_type_to_payee_code(claimant.type))
  end

  def claimant_type_to_payee_code(type)
    case type
    when "VeteranClaimant"
      "00"
    when "DependentClaimant"
      "10"
    else
      Rails.logger.warn("Unsupported claimant type: #{type}")
      # Or add other Claimant types if necessary
    end
  end

  # :reek:FeatureEnvy
  def process_records(record)
    begin
      record.clear_error!
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_errors(record.class.name, record.id, error)
    end
  end

  def hlrs_with_errors
    HigherLevelReview.where("establishment_error ILIKE ?", "%#{error_text}%")
  end

  def appeals_with_errors
    Appeal.where("establishment_error ILIKE ?", "%#{error_text}%")
  end

  def records_with_errors
    hlrs = hlrs_with_errors
    appeals = appeals_with_errors

    all_records_with_errors = hlrs + appeals

    all_records_with_errors
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
