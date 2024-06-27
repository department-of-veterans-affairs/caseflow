# frozen_string_literal: true

# Testing plan:
# - 1. Create test records usiong factories and take note of notification ID and specific fields to compare
# - 2. Use custom message defined here to pass in perform method
# - 3. Test perform method by checking if field values in DB recored are equal to the field values in the message,
# -    An update to record should only be called whenever there are differences between the message and the record in DB
# - 4. The updated record should be returned

describe ReceiveNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  # rubocop:disable Style/BlockDelimiters
  let(:message) {
    {
      queue_url: "http://example_queue",
      message_body: "Notification",
      message_attributes: {
        "id": {
          data_type: "String",
          string_value: "3fa85f64-5717-4562-b3fc-2c963f66afa6"
        },
        "body": {
          data_type: "String",
          string_value: "AString"
        },
        "created_at": {
          data_type: "String",
          string_value: "2022-09-02T20:40:11.184Z"
        },
        "completed_at": {
          data_type: "String",
          string_value: "2022-09-02T20:40:11.184Z"
        },
        "created_by_name": {
          data_type: "String",
          string_value: "John"
        },
        "email_address": {
          data_type: "String",
          string_value: "user@example.com"
        },
        "line_1": {
          data_type: "String",
          string_value: "address"
        },
        "line_2": {
          data_type: "String",
          string_value: "address"
        },
        "line_3": {
          data_type: "String",
          string_value: "address"
        },
        "line_4": {
          data_type: "String",
          string_value: "address"
        },
        "line_5": {
          data_type: "String",
          string_value: "address"
        },
        "line_6": {
          data_type: "String",
          string_value: "address"
        },
        "phone_number": {
          data_type: "String",
          string_value: nil
        },
        "postage": {
          data_type: "String",
          string_value: "postage"
        },
        "postcode": {
          data_type: "String",
          string_value: "postcode"
        },
        "reference": {
          data_type: "String",
          string_value: "9"
        },
        "scheduled_for": {
          data_type: "String",
          string_value: "2022-09-02T20:40:11.184Z"
        },
        "sent_at": {
          data_type: "String",
          string_value: "2022-09-02T20:40:11.184Z"
        },
        "sent_by": {
          data_type: "String",
          string_value: "sent-by"
        },
        "status": {
          data_type: "String",
          string_value: "delivered"
        },
        "subject": {
          data_type: "String",
          string_value: "subject"
        },
        "type": {
          string_value: "email",
          data_type: "String"
        }

      }
    }
  }

  # rubocop:enable Style/BlockDelimiters
  let(:queue_name) { "caseflow_test_receive_notifications" }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(ReceiveNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    # create notification event record
    let(:hearing_scheduled_event) do
      create(:notification_event, event_type: "Hearing scheduled",
                                  email_template_id: "27bf814b-f065-4fc8-89af-ae1292db894e",
                                  sms_template_id: "c2798da3-4c7a-43ed-bc16-599329eaf7cc")
    end
    # create notification record
    let(:notification) do
      create(:notification, id: 9, appeals_id: 4, appeals_type: "Appeal", event_type: "Hearing scheduled",
                            participant_id: "123456789", notification_type: "Email", recipient_email: "",
                            event_date: Time.zone.now, email_notification_status: "Success")
    end

    # add message to queue
    subject(:job) { ReceiveNotificationJob.perform_later(message) }

    # make sure job count increases by 1
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      # After receiving the notification (by notification id), check : if email is same, if number is still nil,
      # if status changed form Success to delivered
      it "updates notification" do
        hearing_scheduled_event
        notification

        # obtain record from compare_notification_audit_record function
        record = ReceiveNotificationJob.perform_now(message)

        # run checks
        expect(record.recipient_email).to eq(message[:message_attributes][:email_address][:string_value])
        expect(record.recipient_phone_number).to eq(nil)
        expect(record.email_notification_status).to eq(message[:message_attributes][:status][:string_value].capitalize)
      end
    end

    describe "errors" do
      it "logs error when message is nil" do
        expect(Rails.logger).to receive(:error).with(/There was no message passed/)
        perform_enqueued_jobs do
          ReceiveNotificationJob.perform_later(nil)
        end
      end

      it "logs error when message_attributes is nil" do
        message[:message_attributes] = nil
        expect(Rails.logger).to receive(:error).with(/message_attributes was nil/)
        perform_enqueued_jobs do
          ReceiveNotificationJob.perform_later(message)
        end
      end
    end
  end
end
