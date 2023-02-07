# frozen_string_literal: true

describe PdfExportService do
  let!(:template_name) { "notification_report_pdf_template.html.erb" }
  let!(:bucket) { "s3_bucket" }
  subject { PdfExportService.create_and_save_pdf(template_name) }
  context "template name doesn't exist" do
    let!(:fake_template) { "asfkdjfkd.html.erb" }
    it "returns MissingTemplate error" do
      PdfExportService.create_and_save_pdf(fake_template)
      error_msg = JSON.parse(response.body)["message"]
      expect(error_msg).to include("Template does not exist for name")
    end
  end
  context "template is rendered successfully" do
    it "creates file in right place" do
      expect(subject).to return(S3_BUCKET_NAME + "/" + file_name)
    end
  end
end
