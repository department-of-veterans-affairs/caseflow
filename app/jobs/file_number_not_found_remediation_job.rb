# frozen_string_literal: true

class FileNumberNotFoundRemediationJob < CaseflowJob
  # CONFIRM WHERE TO RESCUE
  class FileNumberMachesVetFileNumberError < StandardError; end
  class FileNumberIsNilError < StandardError; end
  class DuplicateVeteranFoundError < StandardError; end
  class NoAssociatedRecordsFoundForFileNumberError < StandardError; end

  queue_with_priority :low_priority

  # ASSOCIATED_OBJECTS = FixFileNumberWizard.new::ASSOCIATIONS
  ASSOCIATED_OBJECTS = ["1,12,3"]
  ERROR_TEXT = "FILENUMBER does not exist"

  attr_reader :decision_doc, :veteran, :appeal

  def initialize(veteran)
    @logs = ["VBMS::FILENUMBERERROR Remediation Log"]
    @decision_doc = decision_doc
    @veteran = veteran
    @appeal = appeal
  end

  def perform
    start_fix_veteran(veteran)
  end

  def fetch_file_number_from_bgs_service
   BGSService.new.fetch_file_number_by_ssn(veteran.ssn)
  end

  def start_fix_veteran(veteran)
    file_number = fetch_file_number_from_bgs_service
    binding.pry
    verify_file_number(file_number)

    collections = ASSOCIATED_OBJECTS.map { |klass| FixFileNumberWizard::Collection.new(klass, veteran.ssn) }
    if collections.map(&:count).sum == 0
      fail NoAssociatedRecordsFoundForFileNumberError
    end

    collections.each { |collection| collection.update!(file_number) }
    veteran.update!(file_number: file_number)

    # add logic to confirm its updated
    @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
      " Veteran SSN: #{veteran.ssn}.  Veteran File Number: #{veteran.file_number}.  FileNumber Error Present: No."\
      " Status: Resolved.")

    create_log
  end

  def verify_file_number(file_number)
    binding.pry
    if file_number == veteran.file_number
      fail FileNumberMachesVetFileNumberError
    elsif file_number.nil?
      fail FileNumberIsNilError
    elsif Veteran.find_by(file_number: file_number).present?
      fail DuplicateVeteranFoundError
    end
  end

  def create_log
    content = @logs.join("\n")
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
    file_name = "duplicate-ep-remediation-logs/duplicate-ep-remediation-log-#{Time.zone.now}"

    # Store file to S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
  end
end
