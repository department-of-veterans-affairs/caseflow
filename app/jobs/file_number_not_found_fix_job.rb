# frozen_string_literal: true

require_relative "../../lib/helpers/fix_file_number_wizard"
require_relative "../../lib/helpers/duplicate_veteran_checker"

class FileNumberNotFoundFixJob < CaseflowJob
  include MasterSchedulerInterface
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  queue_with_priority :low_priority
  application_attr :intake

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    super
  end

  def perform
    RequestStore[:current_user] = User.system_user
    start_time
    loop_through_and_call_process_records
    end_time
    log_processing_time
    @stuck_job_report_service.write_log_report(error_text)
  rescue StandardError => error
    log_error(error)
  end

  def loop_through_and_call_process_records
    return if records_with_errors.blank?

    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)

    records_with_errors.each do |decision_document|
      process_records(decision_document)
    end

    # record count with errors after fix
    @stuck_job_report_service.append_record_count(records_with_errors.count, error_text)
  end
  # :reek:FeatureEnvy

  def process_records(decision_doc)
    veteran = decision_doc&.appeal&.veteran
    bgs_file_number = fetch_file_number_from_bgs_service(veteran)
    return if veteran.blank? || bgs_file_number.blank?

    # ensure that there is no duplicate veteran.
    return if Veteran.find_by(file_number: bgs_file_number).present?

    collections = FixfileNumberCollections.get_collections(veteran)

    # ensures that we have related collections else abort.
    return if collections.sum(&:count) == 0

    update_records!(collections, bgs_file_number, veteran)
    @stuck_job_report_service.append_single_record(decision_doc.class.name, decision_doc.id)
    decision_doc.clear_error!
  rescue StandardError => error
    @stuck_job_report_service.append_error(decision_doc.class.name, decision_doc.id, error)
    log_error(error)
  end

  # rubocop:enable

  def error_text
    "FILENUMBER does not exist"
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

  def records_with_errors
    DecisionDocument.where("error LIKE ?", "%#{error_text}%")
  end

  private

  def fetch_file_number_from_bgs_service(veteran)
    FetchFileNumberBySSN.call(veteran.ssn)
  end

  # updates all the related associated objects with the correct
  # file number
  def update_records!(collections, file_number, veteran)
    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)
      end
      veteran.update!(file_number: file_number)
    end
  end

  # created class to mock BGSService
  class FetchFileNumberBySSN
    def self.call(ssn)
      BGSService.new.fetch_file_number_by_ssn(ssn)
    end
  end
end

# created this class below so as to mock FixFileNumberWizard::Collection instance
class FixfileNumberCollections
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS
  def self.get_collections(veteran)
    ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass, veteran.ssn)
    end
  end
end
