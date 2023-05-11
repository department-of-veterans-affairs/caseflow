# frozen_string_literal: true

module AppealNotificationReportConcern
  extend ActiveSupport::Concern

  included do
    if is_a?(Appeal)
      attribute :uuid, :veteran_file_number
    elsif is_a?(LegacyAppeal)
      attribute :vacols_id, :veteran_file_number
    end
  end

  # Exception for when PDF fails to generate
  class PDFGenerationError < StandardError
    def initialize(message = "PDF failed to generate")
      @message = message
      super(message)
    end
  end

  # Exception for when PDF fails to upload
  class PDFUploadError < StandardError
    def initialize(message = "Error while trying to prepare or upload PDF")
      @message = message
      super(message)
    end
  end

  # Purpose: Generate the PDF and then prepares the document for uploading to S3 or VBMS
  # Returns: nil
  def upload_notification_report!
    transmit_document!

    nil
  end

  private

  # Purpose: Creates the name for the document
  # Returns: The document name
  def notification_document_name
    "notification-report_#{external_id}"
  end

  # Purpose: Generates the PDF
  # Returns: The generated PDF encoded in base64
  def notification_report
    begin
      file = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
      Base64.encode64(file)
    rescue StandardError
      raise PDFGenerationError
    end
  end

  def document_params
    {
      veteran_file_number: veteran_file_number,
      document_type: "BVA Case Notifications",
      document_subject: "notifications",
      document_name: notification_document_name,
      application: "notification-report",
      file: notification_report
    }
  end

  def transmit_document!
    document_already_exists? ? update_document : upload_document
  end

  # Purpose: Checks in eFolder for a doc in the veteran's eFolder with the same type
  # Returns: Boolean related to whether a document with the same type already exists
  def document_already_exists?
    # Just putting some thoughts down here. I think this may need to be refined further
    # appeal.vbms_uploaded_documents.where(document_type: "BVA Case Notifications").count > 0

    # Hard-coding this for now
    true
  end

  # Purpose: Uploads the PDF
  # Returns: The job being queued
  def upload_document
    response = PrepareDocumentUploadToVbms.new(document_params, User.system_user, self).call

    fail PDFUploadError unless response.success?
  end

  # Purpose: Kicks off a document update in eFolder to overwrite a previous version of the document
  # Returns: The job being queued
  def update_document
    response = PrepareDocumentUpdateInVbms.new(document_params, User.system_user, self).call

    fail PDFUploadError unless response.success?
  end
end
