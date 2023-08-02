# frozen_string_literal: true

# StuckJobHelper is a generic shared class that creates the logs
# sent to S3. The logs give the count before the remediation and
# the count after the remediation.

# The logs also contain the Id of the record that has been updated

class StuckJobHelper
  @logs = ["#{Time.zone.now} ********** Remediation Log Report **********"]

  # Logs the Id and the object that is being updated
  def self.single_s3_record_log(object)
    @logs.push("\n#{Time.zone.now} Record Type: #{object.class.name} - Record ID: #{object.id}.")
  end

  # Gets the record count of the record type passed in.
  def self.s3_record_count(records, text)
    @logs.push("\n#{Time.zone.now} #{text}::Log - Total number of Records with Errors: #{records.count}")
  end

  def self.create_s3_log_report(error_text)
    temporary_file = Tempfile.new("cdc-log.txt")
    filepath = temporary_file.path
    temporary_file.write(@logs)
    temporary_file.flush
    create_file_name = error_text.split.join("-").downcase
    upload_logs_to_s3(filepath, create_file_name)

    temporary_file.close!
  end

  def self.upload_logs_to_s3(filepath, create_file_name)
    s3client = Aws::S3::Client.new
    s3resource = Aws::S3::Resource.new(client: s3client)
    s3bucket = s3resource.bucket("data-remediation-output")
    file_name = "#{create_file_name}-logs/#{create_file_name}-log-#{Time.zone.now}"

    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
  end
end
