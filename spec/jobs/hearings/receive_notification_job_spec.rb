# frozen_string_literal: true

# Testing plan:
# - 1. Create test records in DB and take note of notification ID and specific fields to compare
# - 2. Use custom messages defined here to grab those test records
# - 3. Test perform method with messages where no values are nil, and with message where some values are nil
# - 4. An update to record should only be called when field values do not match or a field from message is nil
# - 5. The updated record should be returned

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
          string_value: "+16502532222"
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
          string_value: "notification-id"
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
          string_value: "created"
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

  let(:nil_message) {
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
          string_value: nil
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
          string_value: "+16502532222"
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
          string_value: "notification-id"
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
          string_value: nil
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

  let(:queue_name) { "caseflow_test_receive_notifications" }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(ReceiveNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { ReceiveNotificationJob.perform_later(message) }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        perform_enqueued_jobs do
          result = ReceiveNotificationJob.perform_later(message)
          expect(result).to receive(:compare_notification_audit_record)
        end
      end


   
    end
  end
end
