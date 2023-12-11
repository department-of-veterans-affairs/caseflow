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
    # Initialize column width for: ** Stuck Job Scheduler Report Table **
    @colomn_widths = {
      date: 10,
      job_name: 30,
      record_count_before: 20,
      record_count_after: 20,
      processing_time: 15
    }
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

  # Used in StuckJobSchedulerJob to create report table
  def append_job_to_log_table(job_name, record_count_before, record_count_after, processing_time)
    timestamp = Time.zone.now.strftime('%Y-%m-%d')


    update_column_width(:date, formatted_date)
    update_column_width(:job_name, job_name.to_s)
    update_column_width(:record_count_before, record_count_before.to_s)
    update_column_width(:record_count_after, record_count_after.to_s)
    update_column_width(:processing_time, processing_time.to_s)

    entry = "#{formatted_date} | #{job_name.ljust(@column_widths[:job_name])} | #{record_count_before.to_s.rjust(@column_widths[:record_count_before])} | #{record_count_after.to_s.rjust(@column_widths[:record_count_after])} | #{execution_time} sec"

    logs.push(entry)
  end

  def header_string
    header = "Date       | Job Name                      | Record Count Before | Record Count After | Execution Time"
    @logs.push(header)
  end

  def update_column_width(column, value)
    @colomn_widths[column] = value.length if value.length > @colomn_widths[column]
  end
end
