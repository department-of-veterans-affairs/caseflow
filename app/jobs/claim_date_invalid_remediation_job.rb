# frozen_string_literal: true

class ClaimDateInvalidRemediationJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake # ***** Check if this is ok *****

  def initialize
    @logs = ["\nVBMS::ClaimDateInvalid Remediation Log"]
    @remediated_ids = [] # IDs of remediated Decision Documents
    @nonqualifying_ids = [] # IDs of Documents that did not meet requirements for remediation
    super
  end

  def perform
    RequestStore[:current_user] = User&.system_user
    log_total_count
    retrieve_decision_docs_with_errors.each do |decision_document|
      if decision_document.processed_at.present? && decision_document.uploaded_to_vbms_at.present?
        resolve_single_decision_document(decision_document)
        @remediated_ids.push(decision_document.id)
      else
        @nonqualifying_ids.push(decision_document.id)
      end
    end
    @logs.push(["Remediated Decision Document IDs:", @remediated_ids.join("\n")])
    log_total_count
    @logs.push(["Non-qualifying Decision Document IDs:", @nonqualifying_ids.join("\n")])
    create_log
  end

  def resolve_single_decision_document(decision_document)
    ActiveRecord::Base.transaction do
      decision_document.clear_error!
    rescue StandardError
      raise ActiveRecord::Rollback
    end
  end

  def retrieve_decision_docs_with_errors
    DecisionDocument.where("error ILIKE ?", "%ClaimDateDt%")
  end

  def log_total_count
    @logs.push("\n #{Time.zone.now} ClaimDateInvalidRemediationJob::Log - Found #{retrieve_decision_docs_with_errors.count} Decision Document(s) with errors")
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
