# frozen_string_literal: true

describe Api::V1::VaNotifyController, type: :controller do
  include ActiveJob::TestHelper

  before { Seeds::NotificationEvents.new.seed! }
  before(:each) { wipe_queues }
  after(:all) { wipe_queues }

  let(:sqs_client) { SqsService.sqs_client }
  let(:api_key) { ApiKey.create!(consumer_name: "API Consumer").key_string }
  let!(:appeal) { create(:appeal) }
  let!(:queue) { create_queue("receive_notifications", true) }
  let!(:notification_email) do
    create(
      :notification,
      appeals_id: appeal.uuid,
      appeals_type: "Appeal",
      event_date: "2023-02-27 13:11:51.91467",
      event_type: Constants.EVENT_TYPE_FILTERS.quarterly_notification,
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
      event_type: Constants.EVENT_TYPE_FILTERS.quarterly_notification,
      notification_type: "Sms",
      notified_at: "2023-02-28 14:11:51.91467",
      sms_notification_external_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      sms_notification_status: "Preferences Declined"
    )
  end
  let(:default_payload) do
    {
      id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      to: "to",
      status_reason: "status_reason",
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
      notification_type: "Email"
    }
  end

  let(:error_payload1) do
    {
      id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      to: "to",
      status_reason: nil,
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
      notification_type: "Email"
    }
  end

  let(:error_payload2) do
    {
      id: nil,
      to: "to",
      status_reason: "status_reason",
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
      notification_type: "Emailx"
    }
  end

  context "email notification status is changed" do
    before { Seeds::NotificationEvents.new.seed! }

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
        to: "to",
        status_reason: "status_reason",
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

    it "Update job runs cleanly when UUID is missing" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload_fake
      expect(response.status).to eq(200)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
    end
  end

  context "payload missing required params" do
    before { Seeds::NotificationEvents.new.seed! }

    let(:payload_email) do
      error_payload1.deep_dup.tap do |payload|
        payload[:notification_type] = "email"
      end
    end

    it "is missing the id and properly errors out" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload_email

      expect(response.status).to eq(200)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
    end
  end

  context "payload status is delivered and status_reason and to are null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "delivered"
        payload[:status_reason] = nil
        payload[:to] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  context "payload status is delivered and status_reason is null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "delivered"
        payload[:status_reason] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  context "payload status is delivered and to is null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "delivered"
        payload[:to] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  context "payload status is NOT delivered and status reason and to are null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "Pending Delivery"
        payload[:to] = nil
        payload[:status_reason] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  context "payload status is NOT delivered and status reason is null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "Pending Delivery"
        payload[:status_reason] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  context "payload status is NOT delivered and to is null" do
    before { Seeds::NotificationEvents.new.seed! }
    let(:payload) do
      error_payload1.deep_dup.tap do |payload|
        payload[:status] = "Pending Delivery"
        payload[:to] = nil
      end
    end

    it "updates status of notification" do
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :notifications_update, params: payload

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }
      expect(response.status).to eq(200)
    end
  end

  def create_queue(name, fifo = false)
    sqs_client.create_queue({
                              queue_name: "caseflow_test_#{name}#{fifo ? '.fifo' : ''}".to_sym,
                              attributes: fifo ? { "FifoQueue" => "true" } : {}
                            })
  end

  def wipe_queues
    client = SqsService.sqs_client

    queues_to_delete = client.list_queues.queue_urls.filter { |url| url.include?("caseflow_test") }

    queues_to_delete.each { |queue_url| client.delete_queue(queue_url: queue_url) }
  end
end
