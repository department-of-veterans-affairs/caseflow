# frozen_string_literal: true

require_relative "../../lib/helpers/master_scheduler_interface"
require_relative "../../lib/helpers/duplicate_veteran_fixer"

class DuplicateVeteranFixerJob < CaseflowJob
  include MasterSchedulerInterface

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def perform
    start_time

    loop_through_and_call_process_records

    end_time
    log_processing_time
  end

  def check_by_ama_appeal_uuid(appeal_uuid)
    appeal = Appeal.find_by_uuid(appeal_uuid)
    validate_appeal(appeal)
    check_by_duplicate_veteran_file_number(appeal.veteran.file_number)
  end

  def run_remediation_by_ama_appeal_uuid(appeal_uuid)
    appeal = Appeal.find_by_uuid(appeal_uuid)
    validate_appeal(appeal)
    perform(appeal.veteran.file_number)
  end

  def check_by_legacy_appeal_vacols_id(legacy_appeal_vacols_id)
    legacy_appeal = LegacyAppeal.find_by_vacols_id(legacy_appeal_vacols_id)
    validate_legacy_appeal(legacy_appeal_vacols_id)
    check_by_duplicate_veteran_file_number(legacy_appeal.veteran.file_number)
  end

  def run_remediation_by_vacols_id(vacols_id)
    legacy_appeal = LegacyAppeal.find_by_vacols_id(vacols_id)
    validate_legacy_appeal(legacy_appeal)
    perform(legacy_appeal.veteran.file_number)
  end

  ##
  # Obtains list of relations and logs their count to console.
  # @overload Gets list of relations and logs count as a string
  # @param [string] duplicate veteran file number
  # :reek:UtilityFunction
  ##
  def check_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
    dvf = DuplicateVeteranFixer.new(duplicate_veteran_file_number)
    dvf.log_and_get_relations_count
  end

  ##
  # Runs remediation by first listing all relations with duplicate file number
  # then with BGS file number. Updates relations to use BGS file number instead.
  # Verifies update and then deletes duplicate user.
  # @overload Runs remediation
  # @param [string] duplicate veteran file number
  # :reek:UtilityFunction
  ##
  def loop_through_and_call_process_records
    return if records_with_errors.blank?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    records_with_errors.each do |supplemental_claim|
      duplicate_veteran_file_number = supplemental_claim.veteran_file_number

      @stuck_job_report_service.append_single_record(supplemental_claim.class.name, supplemental_claim.id)
      dvf = DuplicateVeteranFixer.new(duplicate_veteran_file_number)
      dvf.run_remediation
      dvf.fixer_logs.each { |str| @stuck_job_report_service.logs.push(str) }
      process_records(supplemental_claim)
    end

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
    @stuck_job_report_service.write_log_report(error_text)
  end

  def error_text
    "VBMS::DuplicateVeteranRecords"
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

  def records_with_errors
    @records_with_errors ||= SupplementalClaim.where("establishment_error ILIKE ?", "%#{error_text}%")
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

  def validate_appeal(appeal)
    run_safeguards("appeal", appeal)
  end

  def validate_legacy_appeal(legacy_appeal)
    run_safeguards("legacy appeal", legacy_appeal)
  end

  ##
  # Checks appeal exist, that the veteran is associated to the appeal,
  # and that veteran is associated to file number.
  # @overload checks appeal, veteran and file number.
  # @parama [string] A string with either "legacay appeal" or "appeal"
  # @param [object] appeal object.
  ##
  def run_safeguards(appeal_type, appeal)
    if appeal.nil?
      Rails.logger.debug("#{appeal_type} was not found. Aborting")
      fail Interrupt
    elsif appeal.veteran.nil?
      Rails.logger.debug("veteran is not assiciated to this #{appeal_type}. Aborting...")
      fail Interrupt
    elsif appeal.veteran.file_number.empty?
      Rails.logger.debug("Veteran tied to #{appeal_type} does not have a file_number. Aborting..")
      fail Interrupt
    end
  end
end
