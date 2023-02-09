# frozen_string_literal: true

describe PdfExportService do
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
    subject { PdfExportService.create_and_save_pdf(template_name, appeal) }
    it "creates file in right place" do
      filepath = template_name + "/" + template_name + ".pdf"
      expect(subject).to eq(filepath)
    end
  end
end
