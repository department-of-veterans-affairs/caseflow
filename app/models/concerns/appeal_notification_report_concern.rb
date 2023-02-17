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

  # rubocop:disable Metrics/MethodLength
  def upload_notification_report!
    time = Time.now.utc
    if is_a?(Appeal)
      document_name = "notification-report_#{uuid}_#{time.strftime('%Y%m%d%k%M%S')}"
    elsif is_a?(LegacyAppeal)
      document_name = "notification-report_#{vacols_id}_#{time.strftime('%Y%m%d%k%M%S')}"
    end
    begin
      file = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
      document_params =
        {
          veteran_file_number: veteran_file_number,
          document_type: "BVA Case Notifications",
          document_subject: "notifications",
          document_name: document_name,
          application: "notification-report",
          file: file
        }
    rescue StandardError
      raise PDFGenerationError
    end
    begin
      PrepareDocumentUploadToVbms.new(document_params, User.system_user, self).call
    rescue StandardError
      raise PDFUploadError
    end
  end
end
# rubocop:enable Metrics/MethodLength
