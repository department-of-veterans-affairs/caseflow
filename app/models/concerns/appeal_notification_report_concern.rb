# frozen_string_literal: true

module AppealNotificationReportConcern
  extend ActiveSupport::Concern

  class PDFGenerationError < StandardError
    def initialize(message = "PDF or file path failed to generate")
      @message = message
      super(message)
    end
  end

  def upload_notification_report!
    begin
      PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
    rescue StandardError
      raise PDFGenerationError
    end
  end
end
