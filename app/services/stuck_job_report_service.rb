# frozen_string_literal: true

# StuckJobReportService is a generic shared class that creates the logs
# sent to S3. The logs give the count before the remediation and
# the count after the remediation.

# The logs also contain the Id of the record that has been updated

class StuckJobReportService
  attr_reader :logs, :folder_name

  S3_FOLDER_NAME = "data-remediation-output"

  def initialize
    @logs = ["#{Time.zone.now} ********** Remediation Log Report **********"]
    @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
  end

  # Logs the Id and the object that is being updated
  def append_single_record(class_name, id)
    logs.push("\n#{Time.zone.now} Record Type: #{class_name} - Record ID: #{id}.")
  end

  def append_error(class_name, id, error)
    logs.push("\n#{Time.zone.now} Record Type: #{class_name}"\
      " - Record ID: #{id}. Encountered #{error}, record not updated.")
  end

  # Gets the record count of the record type passed in.
  def append_record_count(records_with_errors_count, text)
    logs.push("\n#{Time.zone.now} #{text}::Log - Total number of Records with Errors: #{records_with_errors_count}")
  end

  def write_log_report(report_text)
    create_file_name = report_text.split.join("-").downcase
    upload_logs(create_file_name)
  end

  def upload_logs(create_file_name)
    content = logs.join("\n")
    file_name = "#{create_file_name}-logs/#{create_file_name}-log-#{Time.zone.now}"
    S3Service.store_file("#{folder_name}/#{file_name}", content)
  end

  def execution_time(job_name, start_time, end_time)
    execution_time = end_time - start_time
    message = "#{job_name} executed in #{execution_time} seconds."
    logs.push(message)
  end

  def log_time
    Time.zone.now
  end

  def error_count_message(errors_count, job_name)
    if errors_count > 0
      logs.push("#{job_name} has #{errors_count} records with errors.")
    else
      logs.push("#{job_name} has no records with errors.")
    end
  end

  def append_dividier
    logs.push("_________________________________________")
  end
end
