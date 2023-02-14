# frozen_string_literal: true

module AppealNotificationReportConcern
  extend ActiveSupport::Concern

  class PDFGenerationError < StandardError
    def initialize(message = "PDF or file path failed to generate")
      @message = message
      super(message)
    end
  end

  included do
    if is_a?(Appeal) == "Appeal"
      attribute :uuid
    elsif is_a?(Appeal) == "LegacyAppeal"
      attribute :vacols_id
    end
  end

  def file_path_is_valid?(file_path)
    if is_a?(Appeal)
      file_path =~ /notification_report_pdf_template_#{uuid}\.pdf/
    elsif is_a?(LegacyAppeal)
      file_path =~ /notification_report_pdf_template_#{vacols_id}\.pdf/
    end
  end

  def upload_notification_report!
    file_location = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
    fail PDFGenerationError unless file_path_is_valid?(file_location)
    # UploadDocumentToVbmsJob.perform_later(document_source: file_location)
  end
end
