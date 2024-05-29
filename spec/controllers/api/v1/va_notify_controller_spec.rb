# frozen_string_literal: true

describe Api::V1::VaNotifyController, type: :controller do
  include ActiveJob::TestHelper

  before { Seeds::NotificationEvents.new.seed! }

  let(:api_key) { ApiKey.create!(consumer_name: "API Consumer").key_string }
  let!(:appeal) { create(:appeal) }
  let!(:notification_email) do
    create(
      :notification,
      appeals_id: appeal.uuid,
      appeals_type: "Appeal",
      event_date: "2023-02-27 13:11:51.91467",
      event_type: "Quarterly Notification",
      notification_type: "Email",
      notified_at: "2023-02-28 14:11:51.91467",
      email_notification_external_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      email_notification_status: "No Claimant Found"
    )
  end
  let!(:notification_sms) do
    create(
      :notification,
      appeals_id: appeal.uuid,
      appeals_type: "Appeal",
      event_date: "2023-02-27 13:11:51.91467",
      event_type: "Quarterly Notification",
      notification_type: "Email",
      notified_at: "2023-02-28 14:11:51.91467",
      sms_notification_external_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      sms_notification_status: "Preferences Declined"
    )
  end
  let(:default_payload) do
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
      notification_type: ""
    }
  end

  context "email notification status is changed" do
    let(:payload_email) do
      default_payload.deep_dup.tap do |payload|
        payload[:notification_type] = "email"
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload_email

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(notification_email.reload.email_notification_status).to eq("created")
    end
  end

  context "sms notification status is changed" do
    let(:payload_sms) do
      default_payload.deep_dup.tap do |payload|
        payload[:notification_type] = "sms"
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload_sms

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(notification_sms.reload.sms_notification_status).to eq("created")
    end
  end

  context "notification does not exist" do
    let(:payload_fake) do
      {
        id: "fake",
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
        recipient_identifiers: [
          {
            id_type: "VAPROFILEID",
            id_value: "string"
          }
        ],
        reference: "string",
        scheduled_for: "2023-04-17T12:38:48.699Z",
        sent_at: "2023-04-17T12:38:48.699Z",
        sent_by: "string",
        status: "created",
        subject: "string",
        template: {
          id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          uri: "string",
          version: 0
        },
        notification_type: "sms"
      }
    end

    it "Update job raises error if UUID is passed in for a non-existant notification" do
      expect_any_instance_of(ProcessNotificationStatusUpdatesJob).to receive(:log_error) do |_job, error|
        expect(error.message).to eq("No notification matches UUID #{payload_fake.dig(:id)}")
      end

      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload_fake
      expect(response.status).to eq(200)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
    end
  end
end
