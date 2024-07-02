# frozen_string_literal: true

# Houses common methods used for uploading and updating documents in VBMS eFolder
module VbmsDocumentTransactionConcern
  extend ActiveSupport::Concern

  # We have to always download the file from s3 to make sure it exists locally
  # instead of storing it on the server and relying that it will be there
  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
    output_location
  end

  def source
    "BVA"
  end

  def document_type_id
    Document.type_id(document_type)
  end

  def cache_file
    S3Service.store_file(s3_location, Base64.decode64(document.file))
  end

  # :reek:FeatureEnvy
  def persist_efolder_version_info(response, response_key)
    document.update!(
      document_version_reference_id: response.dig(response_key, :@new_document_version_ref_id),
      document_series_reference_id: response.dig(response_key, :@document_series_ref_id)
    )
  end

  def throw_error_if_file_number_not_match_bgs
    bgs_file_number = nil
    if !veteran_file_number.nil?
      bgs_file_number = bgs_service.fetch_file_number_by_ssn(veteran_ssn)
    end
    if bgs_service.fetch_veteran_info(veteran_file_number).nil?
      if !bgs_file_number.blank? && !bgs_service.fetch_veteran_info(bgs_file_number).nil?
        bgs_file_number
      else
        fail(
          Caseflow::Error::BgsFileNumberMismatch,
          file_number: veteran_file_number, user_id: user.id
        )
      end
    else
      veteran_file_number
    end
  end

  private

  def set_processed_at_to_current_time
    document.update!(processed_at: Time.zone.now)
  end

  def save_rescued_error!(error)
    document.update!(error: error, document_version_reference_id: nil)
  end

  def s3_location
    "#{s3_bucket_by_doc_type}/#{pdf_name}"
  end

  def output_location
    File.join(Rails.root, "tmp", "pdfs", pdf_name)
  end

  def pdf_name
    "veteran-#{file_number}-doc-#{document.id}.pdf"
  end

  def file_number
    document.veteran_file_number
  end

  def cleanup_up_file
    File.delete(output_location) if File.exist?(output_location)
  end

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info("#{info_message} ID: #{uuid}")
  end

  # Purpose: Get the s3_sub_bucket based on the document type
  # S3_SUB_BUCKET was previously a constant defined for this class.
  #
  # Params: None
  #
  # Return: string for the sub-bucket
  def s3_bucket_by_doc_type
    case document_type
    when "BVA Case Notifications"
      "notification-reports"
    else
      "idt-uploaded-documents"
    end
  end
end
