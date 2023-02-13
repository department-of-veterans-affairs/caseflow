# frozen_string_literal: true

module AppealNotificationReportConcern
  extend ActiveSupport::Concern

  def upload_notification_report!
    file_location = PdfExportService.create_and_save_pdf("notification_report_pdf_template", self)
  end
end
