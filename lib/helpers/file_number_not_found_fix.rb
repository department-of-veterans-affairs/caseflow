# frozen_string_literal: true

require "./lib/helpers/fix_file_number_wizard"
require "./lib/helpers/duplicate_veteran_checker"

# This .rb file fixes the file number not found error on
# decision documents. The fix can either be run as a
# scheduled job or run against an individual appeal by
# running FileNumberNotFoundFix.new.single_record_fix(appeal)

class FileNumberNotFoundFix
  ERRORTEXT = "FILENUMBER does not exist"

  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  attr_reader :stuck_job_report_service

  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    super
  end

  def fix_multiple_records
    return if bulk_decision_docs_with_error.blank?

    stuck_job_report_service.append_record_count(bulk_decision_docs_with_error.count, ERRORTEXT)

    bulk_decision_docs_with_error.each do |decision_document|
      appeal = decision_document.appeal

      single_record_fix(appeal)
      decision_document.clear_error!
    end

    # record count with errors after fix
    stuck_job_report_service.append_record_count(bulk_decision_docs_with_error.count, ERRORTEXT)
    stuck_job_report_service.write_log_report(ERRORTEXT)
  end

  def single_record_fix(appeal)
    veteran = appeal.veteran
    return unless veteran

    bgs_file_number = fetch_file_number_from_bgs_service(veteran)

    # ensure that file number from bgs exists and is not already used
    return unless bgs_file_number
    # ensure that there is no duplicate veteran.
    return if Veteran.find_by(file_number: bgs_file_number).present?

    collections = FixfileNumberCollections.get_collections(veteran)

    # ensures that we have related collections else abort.
    return if collections.map(&:count).sum == 0

    update_records!(collections, bgs_file_number, veteran)
  rescue StandardError => error
    stuck_job_report_service.append_error(appeal.class.name, appeal.id, error)
    Rails.logger.error("FILENUMBER UPDATE error. Error: #{error}")
  end

  private

  def bulk_decision_docs_with_error
    DecisionDocument.where("error LIKE ?", "%#{ERRORTEXT}%")
  end

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
