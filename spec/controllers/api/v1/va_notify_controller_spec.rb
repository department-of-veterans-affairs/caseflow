# frozen_string_literal: true

describe Api::V1::VaNotifyController, type: :controller do
  let!(:appeal) { create(:appeal) }
  let(:notification_email) { create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Quarterly Notification", notification_type: "Email", notified_at: "2023-02-28 14:11:51.91467", email_notification_external_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6", email_notification_status: "No Claimant Found") }
  let(:notification_sms) { create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2023-02-27 13:11:51.91467", event_type: "Quarterly Notification", notification_type: "Email", notified_at: "2023-02-28 14:11:51.91467", sms_notification_external_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6", sms_notification_status: "Preferences Declined") }
  # let(:msg) { VANotifySendMessageTemplate.new(success_message_attributes, good_template_name) }

  context "notification record not found" do
  end

  context "email notification status is changed" do
    let(:payload_email) do
      {
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        body: "string",
        completed_at: "2023-04-17T12:38:48.699Z",
        created_at: "2023-04-17T12:38:48.699Z",
        created_by_name: "string",
        email_address: "user@example.com",
        line_1: "string",
        line_2: "string",
        line_3: "string",
        line_4: "string",
        line_5: "string",
        line_6: "string",
        phone_number: "+16502532222",
        postage: "string",
        postcode: "string",
        reference: "string",
        scheduled_for: "2023-04-17T12:38:48.699Z",
        sent_at: "2023-04-17T12:38:48.699Z",
        sent_by: "string",
        status: "created",
        subject: "string",
        type: "email"
      }
    end
    it "updates status of notification" do
      byebug
      post :notifications_update, params: payload_email
      expect(notification_email.status).to eq("created")
    end
  end

  context "sms notification status is changed" do
    let(:payload_sms) do
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "body": "string",
        "completed_at": "2023-04-17T12:38:48.699Z",
        "created_at": "2023-04-17T12:38:48.699Z",
        "created_by_name": "string",
        "email_address": "user@example.com",
        "line_1": "string",
        "line_2": "string",
        "line_3": "string",
        "line_4": "string",
        "line_5": "string",
        "line_6": "string",
        "phone_number": "+16502532222",
        "postage": "string",
        "postcode": "string",
        "recipient_identifiers": [
          {
            "id_type": "VAPROFILEID",
            "id_value": "string"
          }
        ],
        "reference": "string",
        "scheduled_for": "2023-04-17T12:38:48.699Z",
        "sent_at": "2023-04-17T12:38:48.699Z",
        "sent_by": "string",
        "status": "created",
        "subject": "string",
        "template": {
          "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "uri": "string",
          "version": 0
        },
        "type": "sms"
      }
    end
    it "updates status of notification" do
      post :notifications_update, params: payload_sms
      expect(notification_email.status).to eq("created")
    end
  end
  context "notification does not exist" do
    let(:payload_fake) do
      {
        "id": "fake",
        "body": "string",
        "completed_at": "2023-04-17T12:38:48.699Z",
        "created_at": "2023-04-17T12:38:48.699Z",
        "created_by_name": "string",
        "email_address": "user@example.com",
        "line_1": "string",
        "line_2": "string",
        "line_3": "string",
        "line_4": "string",
        "line_5": "string",
        "line_6": "string",
        "phone_number": "+16502532222",
        "postage": "string",
        "postcode": "string",
        "recipient_identifiers": [
          {
            "id_type": "VAPROFILEID",
            "id_value": "string"
          }
        ],
        "reference": "string",
        "scheduled_for": "2023-04-17T12:38:48.699Z",
        "sent_at": "2023-04-17T12:38:48.699Z",
        "sent_by": "string",
        "status": "created",
        "subject": "string",
        "template": {
          "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "uri": "string",
          "version": 0
        },
        "type": "sms"
      }
    end
    it "updates status of notification" do
      post :notifications_update, params: payload_fake
      error_msg = JSON.parse(response.body)["message"]
      expect(error_msg).to include("could not be found.")
    end
  end
end
