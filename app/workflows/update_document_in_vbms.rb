# frozen_string_literal: true

class UpdateDocumentInVbms
  delegate :document_type, :document_subject, :document_name, :document_version_reference_id, to: :document

  def initialize(document:)
    @document = document
  end

  def call
    return if document.processed_at

    submit_for_processing!
    update_in_vbms!
    set_processed_at_to_current_time
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

  def update_in_vbms!
    return if document.uploaded_to_vbms_at

    update_response = VBMSService.update_document_in_vbms(document.appeal, self)

    persist_efolder_version_info(update_response)

    document.update!(uploaded_to_vbms_at: Time.zone.now)
  end

  def set_processed_at_to_current_time
    document.update!(processed_at: Time.zone.now)
  end

  def persist_efolder_version_info(response)
    document.update!(
      document_version_reference_id: response.dig(:update_document_response, :@new_document_version_ref_id),
      document_series_reference_id: response.dig(:update_document_response, :@document_series_ref_id)
    )
  end

  def save_rescued_error!(error)
    document.update!(error: error, document_version_reference_id: nil)
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
