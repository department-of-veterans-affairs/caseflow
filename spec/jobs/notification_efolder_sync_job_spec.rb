# frozen_string_literal: true

# * Run specs "bundle exec rspec spec/jobs/notification_efolder_sync_job_spec.rb"

# * Get code coverage "open coverage/index.html"

describe NotificationEfolderSyncJob do
  before do
    Seeds::NotificationEvents.new.seed!
  end

  subject { NotificationEfolderSyncJob.new }

  let(:uuid) { appeal_one.uuid }
  let(:vacols_id) { legacy_appeal_one.vacols_id }

  # * Appeals, vbms_docs and notifications
  # *appeal_one, vbms_docs and notifications ** has notification is after vbms_doc ** Will be in list **
  # rubocop:disable Layout/LineLength
  let(:appeal_one) { create(:appeal) }
  let(:notification_one_appeal_one) { create(:notification, appeals_id: appeal_one.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-28 14:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:notification_two_appeal_one) { create(:notification, appeals_id: appeal_one.uuid, appeals_type: "Appeal", event_date: "2023-02-28 13:11:51.91467", event_type: "Hearing scheduled", notification_type: "Email" , notified_at: "2023-02-29 14:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:document_one_appeal_one) { create(:vbms_uploaded_document, document_type: "BVA Case Notifications", appeal_id: appeal_one.id, appeal_type: "Appeal", created_at: "2023-02-27 13:11:51.91467", uploaded_to_vbms_at: "2023-02-27 13:11:51.91467", attempted_at:"2023-02-27 13:11:51.91467") }
  let(:document_two_appeal_one) { create(:vbms_uploaded_document, document_type: "BVA Case Notifications", appeal_id: appeal_one.id, appeal_type: "Appeal", created_at: "2023-02-28 13:11:51.91467", uploaded_to_vbms_at: "2023-02-28 13:11:51.91467", attempted_at:"2023-02-28 13:11:51.91467") }

  # *appeal_two will not have notification ** Will not be in list **
  let(:appeal_two) { create(:appeal) }
  # * Legacy Appeals, vbms_docs, and notifications
  # *appeal_one, vbms_docs and notifications ** has notification is after vbms_doc ** Will be in list **
  let(:legacy_appeal_one) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let(:notification_one_legacy_appeal_one) { create(:notification, appeals_id: legacy_appeal_one.vacols_id, appeals_type: "LegacyAppeal", event_date: "2023-02-28 07:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-28 07:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:notification_two_legacy_appeal_one) { create(:notification, appeals_id: legacy_appeal_one.vacols_id, appeals_type:"LegacyAppeal", event_date: "2023-02-28 09:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-28 09:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:document_one_legacy_appeal_one) { create(:vbms_uploaded_document, document_type: "BVA Case Notifications", appeal_id: legacy_appeal_one.id, appeal_type: "LegacyAppeal", created_at: "2023-02-27 13:11:51.91467", uploaded_to_vbms_at: "2023-02-27 13:11:51.91467") }
  let(:document_two_legacy_appeal_one) { create(:vbms_uploaded_document, document_type: "BVA Case Notifications", appeal_id: legacy_appeal_one.id, appeal_type: "LegacyAppeal", created_at: "2023-02-28 13:11:51.91467", uploaded_to_vbms_at: "2023-02-27 13:11:51.91467") }
  let(:old_notification) { create(:notification, appeals_id: appeal_one.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-27 14:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:old_document) { create(:vbms_uploaded_document, document_type: "BVA Case Notifications", appeal_id: appeal_one.id, appeal_type: "Appeal", created_at: "2023-02-27 13:11:51.91467", uploaded_to_vbms_at: "2023-02-28 14:11:51.91467", attempted_at: "2023-02-27 15:11:51.91467") }
  let(:new_notification) { create(:notification, appeals_id: appeal_one.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-29 14:11:51.91467", email_notification_status: "Success", sms_notification_status: "Preferences Declined") }
  let(:error_notification) { create(:notification, appeals_id: appeal_one.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-27 14:11:51.91467") }

  # rubocop:enable Layout/LineLength

  # *appeal_two will not have notification ** Will be in list **
  let(:legacy_appeal_two) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }

  context "Tests check_if_record_exist_in_vbms_upload_doc?(appeal) method" do
    it "Returns True if vbms document is present that is associated with appeal" do
      document_two_appeal_one

      is_true = subject.check_if_record_exists_in_vbms_uploaded_doc?(appeal_one)
      expect(is_true).to eq(true)
    end

    it "Returns False if vbms document is present that is associated with appeal" do
      is_true = subject.check_if_record_exists_in_vbms_uploaded_doc?(appeal_one)
      expect(is_true).to eq(false)
    end

    it "Returns True if vbms document is present that is associated with legacy appeal" do
      document_one_legacy_appeal_one
      is_true = subject.check_if_record_exists_in_vbms_uploaded_doc?(legacy_appeal_one)
      expect(is_true).to eq(true)
    end

    it "Returns False if vbms document is present that is associated with legacy appeal" do
      is_true = subject.check_if_record_exists_in_vbms_uploaded_doc?(legacy_appeal_one)
      expect(is_true).to eq(false)
    end
  end

  context "Determines whether a Legacy Appeal or an AMA Appeal" do
    it "If it is an AMA Appeal will return UUID" do
      appeal_one
      expect(subject.unique_identifier(appeal_one)).to eq(uuid)
    end

    it "If it is an Legacy Appeal will return Vacols Id" do
      legacy_appeal_one
      expect(subject.unique_identifier(legacy_appeal_one)).to eq(vacols_id)
    end
  end

  context "Returns last notification associated with an appeal" do
    it "Expects to get the last notification associated with an appeal" do
      appeal_one
      notification_one_appeal_one
      notification_two_appeal_one
      last_notification = subject.last_notification_of_appeal(appeal_one.uuid)
      expect(last_notification).to eq(notification_two_appeal_one)
    end
  end

  context "Returns last uploaded document associated with an appeal or Legacy Appeal" do
    it "Expects to get the last uploaded document associated with an appeal" do
      appeal_one
      document_one_appeal_one
      document_two_appeal_one
      expect(subject.latest_vbms_uploaded_document(appeal_one.id))
      .to eq(document_two_appeal_one)
    end
  end

  context "Tests all logic within the perform method" do
    it "Expects to create only 1 VbmsUploadedDocument for appeals" do
      appeal_one
      appeal_two
      notification_one_appeal_one
      subject.perform_now
      expect(VbmsUploadedDocument.count).to eq(1)
    end

    it "Expects to create only 1 VbmsUploadedDocument for legacy appeals" do
      legacy_appeal_one
      legacy_appeal_two
      notification_two_legacy_appeal_one
      notification_one_legacy_appeal_one
      subject.perform_now
      expect(VbmsUploadedDocument.count).to eq(1)
    end

    it "Expects to create no new VbmsUploadedDocuments when no new notifications" do
      appeal_one
      old_notification
      old_document
      count = VbmsUploadedDocument.count
      subject.perform_now
      expect(VbmsUploadedDocument.count).to eq(count)
    end

    it "Expects to create 1 new VbmsSUploadedDocument when 1 appeal has new notifications" do
      appeal_one
      old_notification
      old_document
      count = VbmsUploadedDocument.count
      new_notification
      subject.perform_now
      expect(VbmsUploadedDocument.count).to eq(count + 1)
    end
  end
end
