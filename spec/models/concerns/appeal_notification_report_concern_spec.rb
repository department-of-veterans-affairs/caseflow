# frozen_string_literal: true

describe AppealNotificationReportConcern do
  before do
    Seeds::NotificationEvents.new.seed!
    Seeds::Notifications.new.seed!
  end
  let(:appeal) { Appeal.find_by_uuid("d31d7f91-91a0-46f8-b4bc-c57e139cee72") }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "123456789S")) }
  let(:appeal_document_name_suffix) {
    "notification-report_d31d7f91-91a0-46f8-b4bc-c57e139cee72"
  }
  let(:legacy_appeal_document_name_suffix) {
    "notification-report_123456"
  }
  let(:legacy_notification) {
    create(:notification,
           appeals_id: "667160001",
           appeals_type: "LegacyAppeal",
           event_date: 8.days.ago,
           notification_type: "Email and SMS",
           event_type: "Appeal docketed")
  }
  context "AMA Appeal" do
    it "document name matches the proper formatting for ama" do
      expect(appeal.send(:notification_document_name)).to include(appeal_document_name_suffix)
    end

    it "pdf is generated successfully" do
      expect(appeal.send(:notification_report)).to be_truthy
    end
  end

  context "Legacy Appeal" do
    it "document name matches the proper formatting for legacy" do
      expect(legacy_appeal.send(:notification_document_name)).to include(legacy_appeal_document_name_suffix)
    end

    it "pdf is generated successfully" do
      legacy_notification
      expect(legacy_appeal.send(:notification_report)).to be_truthy
    end
  end
end
