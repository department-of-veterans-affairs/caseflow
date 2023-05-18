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
    document_params =
      {
        veteran_file_number: veteran_file_number,
        document_type: "BVA Case Notifications",
        document_subject: "notifications",
        document_name: notification_document_name,
        application: "notification-report",
        file: notification_report
      }
    upload_document(document_params)
    nil
  end

  private

  # Purpose: Creates the name for the document
  # Returns: The document name
  def notification_document_name
    if is_a?(Appeal)
      "notification-report_#{uuid}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
    elsif is_a?(LegacyAppeal)
      "notification-report_#{vacols_id}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
    end
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

  # Purpose: Uploads the PDF
  # Returns: The job being queued
  def upload_document(document_params)
    response = PrepareDocumentUploadToVbms.new(document_params, User.system_user, self).call
    if !response.success?
      fail PDFUploadError
    end
  end
end
