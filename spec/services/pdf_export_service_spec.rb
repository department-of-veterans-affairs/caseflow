# frozen_string_literal: true

describe PdfExportService do
  before do
    Seeds::NotificationEvents.new.seed!
    Seeds::Notifications.new.seed!
  end
  let!(:appeal) { Appeal.find_by_uuid("d31d7f91-91a0-46f8-b4bc-c57e139cee72") }
  context "template name doesn't exist" do
    let!(:fake_template) { "asfkdjfkd" }
    it "returns MissingTemplate error" do
      expect(Rails.logger).to receive(:error)
      PdfExportService.create_and_save_pdf(fake_template, appeal)
    end
  end
  context "template is rendered successfully with appeal" do
    let!(:template_name) { "notification_report_pdf_template" }
    subject { PdfExportService.create_and_save_pdf(template_name, appeal) }
    it "creates file" do
      expect(subject).to_not eq(nil)
    end
  end
end
