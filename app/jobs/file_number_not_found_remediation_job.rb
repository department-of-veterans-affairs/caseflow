# frozen_string_literal: true

require "./lib/helpers/fix_file_number_wizard.rb"

class FileNumberNotFoundRemediationJob < CaseflowJob
  # CONFIRM WHERE TO RESCUE
  class FileNumberMachesVetFileNumberError < StandardError; end
  class FileNumberIsNilError < StandardError; end
  class DuplicateVeteranFoundError < StandardError; end
  class NoAssociatedRecordsFoundForFileNumberError < StandardError; end

  queue_with_priority :low_priority

  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  attr_reader :veteran, :appeal

  def initialize(appeal)
    @logs = ["VBMS::FILENUMBERERROR Remediation Log"]
    @appeal = appeal
    @veteran = appeal.veteran
  end

  def perform
    start_fix_veteran
  end

  def fetch_file_number_from_bgs_service
    BGSService.new.fetch_file_number_by_ssn(veteran.ssn)
  end

  def start_fix_veteran
    file_number = fetch_file_number_from_bgs_service
    verify_file_number(file_number)
    collections = ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass, veteran.ssn)
    end

    if collections.map(&:count).sum == 0
      fail NoAssociatedRecordsFoundForFileNumberError
    end

    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)

        # @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
        #   " Veteran SSN: #{veteran.ssn}.  Veteran File Number: #{veteran.file_number}."\
        #   " Object Type: #{collection}.   Object ID: #{collection.id}."\
        #   " Status: File Number Updated.")
      end
      veteran.update!(file_number: file_number)

    rescue StandardError => error
      Rails.logger.error(error)
      raise ActiveRecord::Rollback
    end

    create_log
  end

  def verify_file_number(file_number)
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

    # upload_logs_to_s3(filepath)

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
