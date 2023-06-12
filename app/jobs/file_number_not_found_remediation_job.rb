# frozen_string_literal: true

class FileNumberNotFoundRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS
  ASSOCIATED_OBJECTS = %w[one two].freeze
  ERROR_TEXT = "FILENUMBER does not exist"

  attr_reader :decision_doc

  def initialize(decision_doc)
    @logs = ["VBMS::FILENUMBERERROR Remediation Log"]
    @decision_doc = decision_doc
  end

  def perform
    decision_document_with_errors
  end

  def decision_doc_with_error
    DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
  end

  def decision_document_with_errors
binding.pry
    decision_doc_with_error.map do |decision_doc|
      # "DID not find dude" #add more logic IGNORE this one
      next if find_appeal(decision_doc).blank?

      vet = find_appeal(decision_doc).veteran
      binding.pry
    @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
        " Veteran SSN: #{vet.ssn}.  Veteran File Number: #{vet.file_number}.  FileNumber Error Present: Yes."\
        " Status: Starting to resolve error.")
      fix_file_number(vet.ssn)
    end
  end

  def find_appeal
    @find_appeal ||= decision_doc.appeal
  end

  def extract_file_number_or_ssn(decision_doc)
    error_message = decision_doc.error.split(", ")[4]
    extract_file_number_or_ssn_regex(error_message)
  end

  def extract_file_number_or_ssn_regex(error_message)
    error_message.match(/\d+/).to_s
  end

  def fix_file_number(ssn)
    fetch_file_number_from_vbms(ssn)

    file_number = fetch_file_number_from_vbms(ssn)
    return  if fetch_file_number_from_vbms(ssn).nil?

    verify_file_number(file_number)

    collections = ASSOCIATED_OBJECTS.map { |klass| FixFileNumberWizard::Collection.new(klass, veteran.ssn) }
     if collections.map(&:count).sum == 0
      Rails.logger.info("No associated records found for the current file number. Aborting because this is very strange.")
      return

      # raise error and rescue
    end

    collections.each { |collection| collection.update!(file_number) }
    veteran.update!(file_number: file_number)

    # add logic to confirm its updated
    @logs.push("#{Time.zone.now} FILENUMBERERROR::Log"\
      " Veteran SSN: #{veteran.ssn}.  Veteran File Number: #{veteran.file_number}.  FileNumber Error Present: No."\
      " Status: Resolved.")

    create_log
  end

  def fetch_file_number_from_vbms(ssn)
    BGSService.new.fetch_file_number_by_ssn(ssn)
  end

  def verify_file_number(file_number)
    if file_number == veteran.file_number
      Rails.logger.info("Veteran's file number is already up-to-date.")
    elsif file_number.nil?
      Rails.logger.info("Veteran's file number could not be found in BGS.")
    elsif Veteran.find_by(file_number: file_number).present?
      Rails.logger.info("Duplicate veteran record found. Handling this scenario is not supported yet.")
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
