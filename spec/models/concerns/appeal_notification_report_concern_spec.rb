# frozen_string_literal: true

describe AppealNotificationReportConcern do
  before do
    Seeds::NotificationEvents.new.seed!
    Seeds::Notifications.new.seed!
  end
  # rubocop:disable Style/BlockDelimiters
  let(:appeal) { Appeal.find_by_uuid("d31d7f91-91a0-46f8-b4bc-c57e139cee72") }
  let(:error_appeal) { create(:appeal) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, bfkey: "700230001", bfcorlid: "123456789S")) }
  let(:appeal_document_name_suffix) {
    "notification-report_d31d7f91-91a0-46f8-b4bc-c57e139cee72"
  }
  let(:ama_document_params) {
    {
      veteran_file_number: "999999990",
      document_type: "BVA Letter",
      document_subject: "notifications",
      document_name: appeal_document_name_suffix,
      application: "notification-report",
      file: nil
    }
  }
  let(:legacy_appeal_document_name_suffix) {
    "notification-report_700230001"
  }
  let(:legacy_notification) { Notification.find_by_appeals_id("2226048") }
  let(:legacy_document_params) {
    {
      veteran_file_number: "213912991",
      document_type: "BVA Letter",
      document_subject: "notifications",
      document_name: legacy_appeal_document_name_suffix,
      application: "notification-report",
      file: nil
    }
  }
  # rubocop:enable Style/BlockDelimiters

  context "AMA Appeal" do
    it "document name matches the proper formatting for ama" do
      expect(appeal.send(:notification_document_name)).to include(appeal_document_name_suffix)
    end

    it "pdf is generated successfully" do
      expect(appeal.send(:notification_report)).to be_truthy
    end

    it "VBMS upload job gets queued up" do
      ama_document_params[:file] = appeal.send(:notification_report)
      expect { appeal.send(:upload_document) }.to_not raise_error
    end
  end

  context "Legacy Appeal" do
    it "document name matches the proper formatting for legacy" do
      expect(legacy_appeal.send(:notification_document_name)).to include(legacy_appeal_document_name_suffix)
    end

    it "pdf is generated successfully" do
      legacy_notification.update!(appeals_id: "700230001")
      expect(legacy_appeal.send(:notification_report)).to be_truthy
    end
  end

  context "Exceptions" do
    it "Error in PDF generation should throw a pdf generation error" do
      expect { error_appeal.upload_notification_report! }
        .to raise_error(AppealNotificationReportConcern::PDFGenerationError)
    end

    it "Error in PDF upload should throw a pdf upload error" do
      allow(error_appeal).to receive(:document_params).and_return(ama_document_params)

      expect { error_appeal.send(:upload_document) }
        .to raise_error(AppealNotificationReportConcern::PDFUploadError)
    end
  end
end
