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
    upload_document(document_params)

    nil
  end

  private

  # Purpose: Creates the name for the document
  # Returns: The document name
  def notification_document_name
    "notification-report_#{external_id}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
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

  # Purpose: Adds a new document version to a series in eFolder if a series already exists
  # Returns: The first document ID in the BVA Case Notifications series for the appeal.
  def transmit_document!
    version_id = document_version_ref_id
    version_id.present? ? update_document(version_id) : upload_document
  end

  # Purpose: Checks in eFolder for a doc in the veteran's eFolder with the same type
  # Returns: document_version_reference_id for newest document in series (string) OR nil
  def document_version_ref_id
    response = VBMSService.fetch_document_series_for(self)
    series = response.select { |obj| obj.series_id == document_series_ref_id }
    series&.first&.document_id
  end

  # Purpose: gets the document_series_reference_id of the most recently uploaded notification report
  # Params: none
  # Returns: document_series_reference_id (string)
  def document_series_ref_id
    vbms_uploaded_documents
      .where(document_type: "BVA Case Notifications")
      .where.not(uploaded_to_vbms_at: nil)
      .order(uploaded_to_vbms_at: :desc)
      .first
      &.document_series_reference_id
  end

  # Purpose: Uploads the PDF
  # Returns: The job being queued
  def upload_document
    response = PrepareDocumentUploadToVbms.new(document_params, User.system_user, self).call

    fail PDFUploadError unless response.success?
  end

  # Purpose: Kicks off a document update in eFolder to overwrite a previous version of the document
  # Returns: The job being queued
  def update_document(version_id)
    updated_params = document_params.tap do |params|
      params[:document_version_reference_id] = version_id
    end
    response = PrepareDocumentUpdateInVbms.new(updated_params, User.system_user, self).call

    fail PDFUploadError unless response.success?
  end
end
