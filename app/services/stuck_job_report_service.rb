# frozen_string_literal: true

# StuckJobReportService is a generic shared class that creates the logs
# sent to S3. The logs give the count before the remediation and
# the count after the remediation.

# The logs also contain the Id of the record that has been updated

class StuckJobReportService
  BUCKET_NAME = "data-remediation-output"
  attr_reader :logs

  def initialize
    @logs = ["#{Time.zone.now} ********** Remediation Log Report **********"]
  end

  # Logs the Id and the object that is being updated
  def append_single_record(class_name, id)
    logs.push("\n#{Time.zone.now} Record Type: #{class_name} - Record ID: #{id}.")
  end

  def append_error(class_name, id, error)
    logs.push("\n#{Time.zone.now} Record Type: #{class_name} - Record ID: #{id}. Encountered #{error}, record not updated.")
  end

  # Gets the record count of the record type passed in.
  def append_record_count(records_with_errors_count, text)
    logs.push("\n#{Time.zone.now} #{text}::Log - Total number of Records with Errors: #{records_with_errors_count}")
  end

  def write_log_report(error_text)
    temporary_file = Tempfile.new("cdc-log.txt")
    filepath = temporary_file.path
    temporary_file.write(logs)
    temporary_file.flush
    create_file_name = error_text.split.join("-").downcase
    upload_logs_to_s3(filepath, create_file_name)

    temporary_file.close!
  end

  def upload_logs_to_s3(filepath, create_file_name)
    s3client = Aws::S3::Client.new
    s3resource = Aws::S3::Resource.new(client: s3client)
    s3bucket = s3resource.bucket(BUCKET_NAME)
    file_name = "#{create_file_name}-logs/#{create_file_name}-log-#{Time.zone.now}"

    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
  end
end
