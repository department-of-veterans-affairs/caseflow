# frozen_string_literal: true

class UploadDocumentToVbms
  delegate :document_type, :document_subject, :document_name, to: :document

  def initialize(document:)
    @document = document
  end

  def call
    return if document.processed_at

    submit_for_processing!
    upload_to_vbms!
    set_processed_at_to_current_time
    log_info("Document #{document.id} uploaded to VBMS")
  rescue StandardError => error
    save_rescued_error!(error.to_s)
    raise error
  end

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

  private

  attr_reader :document

  def submit_for_processing!
    when_to_start = Time.zone.now

    document.update!(
      last_submitted_at: when_to_start,
      submitted_at: when_to_start,
      processed_at: nil,
      attempted_at: when_to_start
    )
  end

  def upload_to_vbms!
    return if document.uploaded_to_vbms_at

    VBMSService.upload_document_to_vbms_veteran(file_number, self)
    document.update!(uploaded_to_vbms_at: Time.zone.now)
  end

  def set_processed_at_to_current_time
    document.update!(processed_at: Time.zone.now)
  end

  def save_rescued_error!(error)
    document.update!(error: error)
  end

  def s3_location
    s3_bucket_by_doc_type + "/" + pdf_name
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

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + "ID: " + uuid)
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
