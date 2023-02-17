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

  class PDFGenerationError < StandardError
    def initialize(message = "PDF or file path failed to generate")
      @message = message
      super(message)
    end
  end

  class PDFUploadError < StandardError
    def initialize(message = "Error while trying to prepare or upload PDF")
      @message = message
      super(message)
    end
  end

  def upload_notification_report!
    begin
      document_params =
        {
          veteran_file_number: veteran_file_number,
          document_type: "BVA Case Notifications",
          document_subject: "notifications",
          document_name: notification_document_name,
          application: "notification-report",
          file: notification_report
        }
      PrepareDocumentUploadToVbms.new(document_params, User.system_user, self).call
    rescue StandardError
      raise PDFUploadError
    end
  end

  private

  def notification_document_name
    if is_a?(Appeal)
      "notification-report_#{uuid}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
    elsif is_a?(LegacyAppeal)
      "notification-report_#{vacols_id}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
    end
  end

  def notification_report
    begin
      file = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
    rescue StandardError
      raise PDFGenerationError
    end
    Base64.encode64(file)
  end
end
