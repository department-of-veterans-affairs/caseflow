# frozen_string_literal: true

# This .rb file fixes the ClaimDateEstablished error. The logic
# checks to ensure that the associcated epe has the code and established_at
# fields populated. If that is the case then we clear the errror field on the
# associated decision document.

# This is going to be a scheduled job. However, we can manually call it from
# the rails console by ClaimDateEstablishedRemediationJob.new.perform
class ClaimDateEstablishedRemediationJob < CaseflowJob
  # most 930 and 682 are very rare but they have occured in the past and as
  # such we added it to the list.
  EPECODES = %w[030 040 930 682].freeze
  attr_reader :logs
  queue_with_priority :low_priority
  application_attr :intake

  def initialize
    @logs = ["\nVBMS::ClaimDateEstablished Remediation Log"]
  end

  def perform
    RequestStore[:current_user] = User&.system_user

    multiple_record_fix
  end

  def multiple_record_fix
    decision_document_with_errors.each do |single_decision_document|
      file_number = single_decision_document.veteran.file_number

      epe = EndProductEstablishment.find_by(veteran_file_number: file_number)
      return unless check_error_records(epe)

      single_decision_document.clear_error!

      logs.push("#{Time.zone.now} ClaimDateEstablished::Log"\
        " Decision Document: #{single_decision_document.id}. Source Type: #{epe.source_type}."\
        " EPE id: #{epe.id}. Status: Updated")
    end
  rescue StandardError => error
    Rails.logger.error("ClaimDateEstablishment Fail: #{error}")

    create_log
  end

  def vet_file_number(decision_document)
    decision_document.veteran.file_number
  end

  def check_error_records(epe)
    epe_code_code = epe&.code.slice(0, 3)
    EPECODES.include?(epe_code_code) && epe&.established_at.present?
  end

  def decision_document_with_errors
    DecisionDocument.where("error ILIKE ?", "%Claim not established%")
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
    file_name = "claim-date-established-remediation-logs/claim-date-established-remediation-log-#{Time.zone.now}"

    # Store file to S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
  end
end
