# frozen_string_literal: true

describe ProcessNotificationStatusUpdatesJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) { wipe_queues }
  after(:all) { wipe_queues }

  let(:sqs_client) { SqsService.sqs_client }

  context ".perform" do
    before { Seeds::NotificationEvents.new.seed! }

    subject(:job) { ProcessNotificationStatusUpdatesJob.perform_later }

    let(:appeal) { create(:appeal, veteran_file_number: "500000102", receipt_date: 6.months.ago.to_date.mdY) }

    let(:email_external_id) { SecureRandom.uuid }
    let(:email_notification) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: Constants.EVENT_TYPE_FILTERS.quarterly_notification,
                            notification_type: "Email",
                            email_notification_external_id: email_external_id)
    end

    let(:sms_external_id) { SecureRandom.uuid }
    let(:sms_notification) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: Constants.EVENT_TYPE_FILTERS.hearing_scheduled,
                            sms_notification_external_id: sms_external_id,
                            notification_type: "SMS")
    end

    let(:sms_notification_2) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: Constants.EVENT_TYPE_FILTERS.postponement_of_hearing,
                            sms_notification_external_id: "1234",
                            notification_type: "SMS")
    end

    it "has one message in queue" do
      expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    context "Updates are pulled from the SQS queue and applied to the datebase" do
      let(:recipient_email) { "test@test.com" }
      let(:email_status) { "delivered" }
      let(:email_status_reason) { "Email delivery was succesful" }

      let(:recipient_phone) { "123-456-7890" }
      let(:sms_status) { "temporary-failure" }
      let(:sms_status_reason) { "Provider is retrying." }

      let(:test_queue) do
        sqs_client.create_queue({
                                  queue_name: "caseflow_test_receive_notifications.fifo".to_sym,
                                  attributes: {
                                    "FifoQueue" => "true"
                                  }
                                })
      end
      let(:queue_url) { test_queue.queue_url }
      let!(:sms_sqs_message) do
        sqs_client.send_message(
          queue_url: queue_url,
          message_body: {
            notification_type: "sms",
            external_id: sms_external_id,
            status: sms_status,
            status_reason: sms_status_reason,
            recipient: recipient_phone
          }.to_json,
          message_deduplication_id: "1",
          message_group_id: ProcessNotificationStatusUpdatesJob::MESSAGE_GROUP_ID
        )
      end

      let!(:sms_sqs_message_wrong_group_id) do
        sqs_client.send_message(
          queue_url: queue_url,
          message_body: {
            notification_type: "sms",
            external_id: "1234",
            status: sms_status,
            status_reason: sms_status_reason,
            recipient: recipient_phone
          }.to_json,
          message_deduplication_id: "2",
          message_group_id: "SomethingElse"
        )
      end

      let!(:email_sqs_message) do
        sqs_client.send_message(
          queue_url: queue_url,
          message_body: {
            notification_type: "email",
            external_id: email_external_id,
            status: email_status,
            status_reason: email_status_reason,
            recipient: recipient_email
          }.to_json,
          message_deduplication_id: "3",
          message_group_id: ProcessNotificationStatusUpdatesJob::MESSAGE_GROUP_ID
        )
      end

      it "Status update info from messages with correct group ID is persisted correctly" do
        expect(all_message_info_empty?).to eq true

        perform_enqueued_jobs { job }

        # Reload records
        [email_notification, sms_notification, sms_notification_2].each(&:reload)

        expect(email_notification.email_notification_status).to eq email_status
        expect(email_notification.email_status_reason).to eq email_status_reason
        expect(email_notification.recipient_email).to eq recipient_email

        expect(sms_notification.sms_notification_status).to eq sms_status
        expect(sms_notification.sms_status_reason).to eq sms_status_reason
        expect(sms_notification.recipient_phone_number).to eq recipient_phone

        # Update with the wrong message_group_id should have been skipped.
        expect([
          sms_notification_2.sms_notification_status,
          sms_notification_2.sms_status_reason,
          sms_notification_2.recipient_phone_number
        ].all?(&:nil?)).to eq true
      end
    end
  end

  def all_message_info_empty?
    [
      email_notification.email_notification_status,
      email_notification.email_status_reason,
      email_notification.recipient_email
    ].all?(&:nil?) &&
      [
        sms_notification.sms_notification_status,
        sms_notification.sms_status_reason,
        sms_notification.recipient_phone_number
      ].all?(&:nil?) &&
      [
        sms_notification_2.sms_notification_status,
        sms_notification_2.sms_status_reason,
        sms_notification_2.recipient_phone_number
      ].all?(&:nil?)
  end

  def wipe_queues
    client = SqsService.sqs_client

    queues_to_delete = client.list_queues.queue_urls.filter { |url| url.include?("caseflow_test") }

    queues_to_delete.each { |queue_url| client.delete_queue(queue_url: queue_url) }
  end
end
