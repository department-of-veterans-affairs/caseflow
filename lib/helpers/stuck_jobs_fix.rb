# frozen_string_literal: true

module WarRoom
  class StuckJobsFix
    EPECODES = %w[030 040 930 682].freeze

    attr_reader :error_text, :object_type, :logs

    def initialize(object_type, error_text)
      @error_text = error_text
      @object_type = object_type
      @logs = ["\nVBMS::#{error_text} Remediation Log"]
    end

    def records_with_errors
      case object_type
      when "decision_document"
        DecisionDocument.where("error ILIKE ?", "%#{error_text}%")
      when "supplemental_claim"
        SupplementalClaim.where("establishment_error ILIKE ?", "%#{error_text}%")
      else
        HigherLevelReview.where("establishment_error ILIKE ?", "%#{error_text}%")
      end
    end

    def dta_sc_creation_failed_fix
      return if records_with_errors.blank?

      s3_record_count

      records_with_errors.each do |hlr|
        return unless SupplementalClaim.find_by(
          decision_review_remanded_id: hlr.id,
          decision_review_remanded_type: "HigherLevelReview"
        )

        single_s3_record_log(hlr)
        clear_error_on_record(hlr)
      end

      s3_record_count

      create_s3_log_report
    end

    def claim_date_dt_fix
      return if records_with_errors.blank?

      s3_record_count

      records_with_errors.each do |single_decision_document|
        return unless single_decision_document.processed_at.present? &&
                      single_decision_document.uploaded_to_vbms_at.present?

        single_s3_record_log(single_decision_document)
        clear_error_on_record(single_decision_document)
      end

      s3_record_count

      create_s3_log_report
    end

    def claim_not_established_fix
      return if records_with_errors.blank?

      s3_record_count

      records_with_errors.each do |single_decision_document|
        file_number = single_decision_document.veteran.file_number
        epe = EndProductEstablishment.find_by(veteran_file_number: file_number)
        return unless validate_epe(epe)

        single_s3_record_log(single_decision_document)

        clear_error_on_record(single_decision_document)
      end

      s3_record_count
      create_s3_log_report
    end

    private

    def format_record_s3_log_text
      error_text.split.join("_").camelize
    end

    def single_s3_record_log(object)
      logs.push("#{Time.zone.now} #{format_record_s3_log_text}::Log" \
        " Record Type: #{object_type}. Record ID: #{object.id}.")
    end

    def s3_record_count
      logs.push("\n #{Time.zone.now} #{format_record_s3_log_text}::Log - Summary Report. Total number of Records with Errors: #{records_with_errors.count}")
    end

    def validate_epe(epe)
      epe_code = epe&.code&.slice(0, 3)
      EPECODES.include?(epe_code) && epe&.established_at.present?
    end

    def clear_error_on_record(object_type)
      ActiveRecord::Base.transaction do
        object_type.clear_error!
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    def create_s3_log_report
      content = logs.join("\n")
      temporary_file = Tempfile.new("cdc-log.txt")
      filepath = temporary_file.path
      temporary_file.write(content)
      temporary_file.flush

      upload_logs_to_s3(filepath)

      temporary_file.close!
    end

    def upload_logs_to_s3(filepath)
      create_file_name = error_text.split.join("-").downcase
      s3client = Aws::S3::Client.new
      s3resource = Aws::S3::Resource.new(client: s3client)
      s3bucket = s3resource.bucket("data-remediation-output")
      file_name = "#{create_file_name}-logs/#{create_file_name}-log-#{Time.zone.now}"

      # Store file to S3 bucket
      s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
    end
  end
end
