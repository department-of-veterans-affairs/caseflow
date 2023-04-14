# frozen_string_literal: true

describe Api::V1::VaNotifyController, type: :controller do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let!(:notification_email) { create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-28 14:11:51.91467", email_notification_status: "No Claimant Found") }
  let!(:notification_sms) { create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Appeal docketed", notification_type: "Email", notified_at: "2023-02-28 14:11:51.91467", sms_notification_status: "Preferences Declined") }
  let(:msg) { VANotifySendMessageTemplate.new(success_message_attributes, good_template_name) }

  context "notification record not found" do
  end

  context "email notification status is changed" do
    let(:payload) do
      {
        "appeals_id": appeal.uuid,
        "appeals_type": "Appeal",
        "created_at": params["created_at"],
        "email_enabled": true,
        "email_notification_content": msg,
        "email_notification_external_id": notification_email.id,
        "email_notification_status": "Success",
        "event_date": params["event_date"],
        "event_type": params["event_type"],
        "notification_content": params["notification_content"],
        "notification_type": params["notification_type"],
        "notified_at": params["notified_at"],
        "participant_id": params["participant_id"],
        "recipient_email": params["recipient_email"],
        "recipient_phone_number": params["recipient_phone_number"],
        "updated_at": params["updated_at"]
    }
    end
  end

  context "sms notification status is changed" do
    let(:payload) do
      {
        "appeals_id": appeal.uuid,
        "appeals_type": "Appeal",
        "created_at": params["created_at"],
        "email_enabled": false,
        "event_date": params["event_date"],
        "event_type": params["event_type"],
        "notification_content": params["notification_content"],
        "notification_type": params["notification_type"],
        "notified_at": params["notified_at"],
        "participant_id": params["participant_id"],
        "recipient_email": params["recipient_email"],
        "recipient_phone_number": params["recipient_phone_number"],
        "sms_notification_content": params["sms_notification_content"],
        "sms_notification_external_id": params["sms_notification_external_id"],
        "sms_notification_status": params["sms_notification_status"],
        "updated_at": params["updated_at"]
    }
    end
  end

end
