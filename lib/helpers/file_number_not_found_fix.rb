# frozen_string_literal: true

require "./lib/helpers/fix_file_number_wizard.rb"
require "./lib/helpers/duplicate_veteran_checker.rb"

# This .rb file fixes the file number not found error on
# decision documents. The fix can either be run as a
# scheduled job or run against an individual appeal by
# running FileNumberNotFoundFix.new.single_record_fix(appeal)

class FileNumberNotFoundFix
  attr_reader :logs
  # frozen_string_literal: true
  ERROR_TEXT = "FILENUMBER does not exist"

  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def initialize
    @logs = ["VBMS::FILENUMBERERROR Remediation Log"]
  end

  def fix_multiple_records
    logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
      " Records with errors: #{bulk_decision_docs_with_error.count}. "\
      " Status: Starting fix.")

    bulk_decision_docs_with_error.each do |decision_document|
      appeal = decision_document.appeal

      return unless duplicate_vet?(appeal.veteran_file_number)

      single_record_fix(appeal, log_to_s3: false)

      decision_document.update(error: nil)
    end
    logs .push("#{Time.zone.now} FILENUMBERERROR::Log"\
      " Records with errors: #{bulk_decision_docs_with_error.count}. "\
      " Status: Complete.")

    create_log
  end

  def duplicate_vet?(file_number)
    DuplicateVeteranChecker.new.check_by_duplicate_veteran_file_number(file_number)
  end

  def single_record_fix(appeal, log_to_s3: true)
    veteran = appeal.veteran
    bgs_file_number = fetch_file_number_from_bgs_service(veteran)

    # ensure that file number from bgs exists and is not already used
    return unless bgs_file_number
    return if Veteran.exists?(file_number: bgs_file_number)

    collections = FixfileNumberCollections.get_collections(veteran)

    # ensures that we have related collections else abort.
    return if collections.map(&:count).sum == 0

    update_records!(collections, bgs_file_number, veteran)
    logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
      " Participant Id: #{veteran.participant_id}.Veteran File Number: #{bgs_file_number}."\
      " Status: File Number Updated.")

    create_log if log_to_s3
  rescue StandardError => error
    Rails.logger.error("FILENUMBER UPDATE error. Error: #{error}")
  end

  private

  def bulk_decision_docs_with_error
    DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
  end

  def fetch_file_number_from_bgs_service(veteran)
    FetchFileNumberBySSN.call(veteran.ssn)
  end

  # updates all the related accoicated objects with the correct
  # file number
  def update_records!(collections, file_number, veteran)
    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)
        logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
          " collection: #{collection.klass.name}. ."\
          " Status: Successful.")
      end
      veteran.update!(file_number: file_number)
    end
  end

  def create_log
    content = logs.join("\n")
    temporary_file = Tempfile.new("cdc-log.txt")
    filepath = temporary_file.path
    temporary_file.write(content)
    temporary_file.flush

    upload_logs_to_s3(filepath)

    temporary_file.close!
  end

  def upload_logs_to_s3(filepath)
    s3client = Aws::S3::Client.new
    s3resource = Aws::S3::Resource.new(client: s3client)
    s3bucket = s3resource.bucket("data-remediation-output")
    file_name = "file-number-remediation-logs/file-number-remediation-log-#{Time.zone.now}"

    # Store file to S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
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
