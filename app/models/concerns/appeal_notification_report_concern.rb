# frozen_string_literal: true

module AppealNotificationReportConcern
  extend ActiveSupport::Concern

  included do
    attribute :veteran_file_number
  end

  class PDFGenerationError < StandardError
    def initialize(message = "PDF or file path failed to generate")
      @message = message
      super(message)
    end
  end

  def upload_notification_report!
    begin
      file = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
      document_params =
        {
          veteran_file_number: veteran_file_number,
          document_type: "BVA Case Notifications",
          document_name: "notification-report",
          application: "notification-report",
          file: file
        }
    rescue StandardError
      raise PDFGenerationError
    end
  end
end
