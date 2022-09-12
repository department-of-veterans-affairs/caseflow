# frozen_string_literal: true

describe SendNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:notification) { create(:notification, appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576", appeals_type: "Appeal", event_type: "Hearing scheduled", event_date: Time.zone.today, notification_type: "Email") }
  # rubocop:disable Style/BlockDelimiters
  let(:good_template_name) { "Appeal docketed" }
  let(:error_template_name) { "No Participant Id Found" }
  let(:success_status) { "Success" }
  let(:error_status) { "No participant_id" }
  let(:success_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
      appeal_type: "Appeal"
    }
  }
  let(:error_message_attributes) {
    {
      participant_id: nil,
      status: error_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1578",
      appeal_type: "Appeal"
    }
  }
  let(:fail_create_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
      appeal_type: nil
    }
  }
  let(:good_message) { VANotifySendMessageTemplate.new(success_message_attributes, good_template_name) }
  let(:bad_message) { VANotifySendMessageTemplate.new(error_message_attributes, error_template_name) }
  let(:fail_create_message) { VANotifySendMessageTemplate.new(fail_create_message_attributes, error_template_name) }
  let(:participant_id) { success_message_attributes[:participant_id] }
  let(:bad_participant_id) { "123" }
  let(:appeal_id) { success_message_attributes[:appeal_id] }
  let(:email_template_id) { "d78cdba9-f02f-43dd-ab89-3ce42cc88078" }
  let(:bad_response) {
    HTTPI::Response.new(
      400,
      {},
      OpenStruct.new(
        "error": "BadRequestError",
        "message": "participant id is not valid"
      )
    )
  }
  let(:good_response) {
    HTTPI::Response.new(
      200,
      {},
      OpenStruct.new(
        "id": SecureRandom.uuid,
        "reference": "string",
        "uri": "string",
        "template": {
          "id" => email_template_id,
          "version" => 0,
          "uri" => "string"
        },
        "scheduled_for": "string",
        "content": {
          "body" => "string",
          "subject" => "string"
        }
      )
    )
  }
  let(:notification_events_id) { "VSO IHP complete" }
  let(:notification_type) { "VSO IHP complete" }
  let(:queue_name) { "caseflow_test_send_notifications" }
  # rubocop:enable Style/BlockDelimiters

  before do
    Seeds::NotificationEvents.new.seed!
  end

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(SendNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { SendNotificationJob.perform_later(good_message.to_json) }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        perform_enqueued_jobs do
          result = SendNotificationJob.perform_later(good_message.to_json)
          expect(result.arguments[0]).to eq(good_message.to_json)
        end
      end

      it "logs error when message is nil" do
        expect(Rails.logger).to receive(:error).with(/There was no message passed/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(nil)
        end
      end

      it "logs error when appeals_id, appeals_type, or event_type is nil" do
        expect(Rails.logger).to receive(:error).with(/appeals_id or appeal_type or event_type/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(fail_create_message.to_json)
        end
      end

      it "logs error when audit record is nil" do
        allow_any_instance_of(SendNotificationJob).to receive(:create_notification_audit_record).and_return(nil)
        expect(Rails.logger).to receive(:error).with(/Audit record was unable to be found or created/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(good_message.to_json)
        end
      end

      it "sends to VA Notify when no errors are present" do
        expect(Rails.logger).not_to receive(:error)
        expect { SendNotificationJob.perform_now(good_message.to_json).to receive(:send_to_va_notify) }
      end

      it "saves to db but does not notify when status is not Success" do
        expect(Rails.logger).not_to receive(:error)
        expect { SendNotificationJob.perform_now(good_message.to_json).not_to receive(:send_to_va_notify) }
      end
    end

    describe "handling errors" do
      it "retries on internal server error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on not found error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyNotFoundError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on rate limit error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyRateLimitError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "discards on unauthorized error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyUnauthorizedError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "discards on forbidden error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyForbiddenError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on retriable error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect_any_instance_of(SendNotificationJob).to receive(:retry_job)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(good_message.to_json)
        end
      end
    end
  end

  context "va_notify FeatureToggles" do
    describe "email" do
      it "is expected to send when the feature toggle is on" do
        FeatureToggle.enable!(:va_notify_email)
        expect(VANotifyService).to receive(:send_email_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the notification_audit_record with content" do
        FeatureToggle.enable!(:va_notify_email)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.notification_content).not_to eq(nil)
      end
      it "is expected to not send when the feature toggle is off" do
        FeatureToggle.disable!(:va_notify_email)
        expect(VANotifyService).not_to receive(:send_email_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
    end

    describe "sms" do
      it "is expected to send when the feature toggle is on" do
        FeatureToggle.enable!(:va_notify_sms)
        expect(VANotifyService).to receive(:send_sms_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the notification_audit_record with content" do
        FeatureToggle.enable!(:va_notify_sms)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.notification_content).not_to eq(nil)
      end
      it "is expected to not send when the feature toggle is off" do
        FeatureToggle.disable!(:va_notify_sms)
        expect(VANotifyService).not_to receive(:send_sms_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
    end
  end

  context "on retry" do
    describe "notification object" do
      it "does not create multiple notification objects" do
        FeatureToggle.enable!(:va_notify_email)
        job = SendNotificationJob.new(good_message.to_json)
        job.instance_variable_set(:@notification_audit_record, notification)
        expect(Notification).not_to receive(:create)
        job.perform_now
      end
    end
  end
end
