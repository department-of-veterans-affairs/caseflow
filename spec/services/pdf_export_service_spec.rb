# frozen_string_literal: true

describe PdfExportService do
  before do
    Seeds::NotificationEvents.new.seed!
  end
  let!(:appeal) { create(:appeal) }
  context "template name doesn't exist" do
    let!(:fake_template) { "asfkdjfkd" }
    it "returns MissingTemplate error" do
      expect(Rails.logger).to receive(:error)
      PdfExportService.create_and_save_pdf(fake_template, appeal)
    end
  end
  context "template is rendered successfully with appeal" do
    let!(:template_name) { "notification_report_pdf_template" }
    let!(:notification) do
      create(:notification, appeals_id: appeal.uuid, appeals_type: appeal.class.name)
    end
    subject { PdfExportService.create_and_save_pdf(template_name, appeal) }
    it "returns the pdf" do
      expect(subject.include?("PDF")).to eq(true)
    end
  end
end
