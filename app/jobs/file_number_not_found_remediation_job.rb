# frozen_string_literal: true

require "./lib/helpers/fix_file_number_wizard.rb"

class FileNumberNotFoundRemediationJob < CaseflowJob
  class FileNumberMachesVetFileNumberError < StandardError; end
  class FileNumberNotFoundError < StandardError; end
  class DuplicateVeteranFoundError < StandardError; end
  class NoAssociatedRecordsFoundForFileNumberError < StandardError; end
  class VeteranSsnDoesNotMatchFileNumberError < StandardError; end

  queue_with_priority :low_priority

  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  attr_reader :appeal

  def initialize(appeal)
    @logs = ["VBMS::FILENUMBERERROR Remediation Log"]
    @appeal = appeal
    @veteran = appeal.veteran
  end

  def perform
    start_fix_veteran
  end

  def fetch_file_number_from_bgs_service
    BGSService.new.fetch_file_number_by_ssn(@veteran.ssn)
  end

  def start_fix_veteran
    file_number = fetch_file_number_from_bgs_service

    raise FileNumberNotFoundError unless file_number

    verify_file_number(file_number)

    collections = ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass,  @veteran.ssn)
    end

    if collections.map(&:count).sum == 0
      raise NoAssociatedRecordsFoundForFileNumberError
    end

    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)

        @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
          " collection: #{ collection.klass.name}. ."\
          " Status: collection.")
      end

       @veteran.update!(file_number: file_number)
      @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
        " Participant Id: #{ @veteran.participant_id}. @veteran File Number: #{ @veteran.file_number}."\
        " Status: File Number Updated.")

    rescue StandardError => error
      @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
        " Participant Id: #{ @veteran.participant_id}.  Veteran File Number: #{ @veteran.file_number}."\
        " Error: #{error} Status: Update failed.")
      raise ActiveRecord::Rollback
    end
    create_log
  end

  def verify_file_number(file_number)
    if file_number == @veteran.file_number
      raise FileNumberMachesVetFileNumberError
    elsif file_number.nil?
      raise FileNumberNotFoundError
    elsif Veteran.find_by(file_number: file_number).present?
      raise DuplicateVeteranFoundError
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
    file_name = "file-number-remediation-logs/file-number-remediation-log-#{Time.zone.now}"

    # Store file to S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
  end
end
