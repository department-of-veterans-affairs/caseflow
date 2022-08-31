# frozen_string_literal: true

describe SendNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  # rubocop:disable Style/BlockDelimiters
  let(:message) {
    {
      queue_url: "http://example_queue",
      message_body: "Notification",
      message_attributes: {
        "participant_id": {
          data_type: "String",
          string_value: "123456789"
        },
        "template_name": {
          data_type: "String",
          string_value: "VSO IHP complete"
        },
        "appeal_id": {
          data_type: "String",
          string_value: "5d70058f-8641-4155-bae8-5af4b61b1576"
        },
        "appeal_type": {
          string_value: "ama",
          data_type: "String"
        }
      }
    }
  }
  let(:participant_id) { message[:message_attributes][:participant_id][:string_value] }
  let(:bad_participant_id) { "123" }
  let(:appeal_id) { message[:message_attributes][:appeal_id][:string_value] }
  let(:email_template_id) { "d78cdba9-f02f-43dd-ab89-3ce42cc88078" }
  let(:appeal_status) { "" }
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

  # rspec for feature toggle is turned on, it should allow the message listener to send
  
   context "va_notify_sms FeatureToggle" do
      before{FeatureToggle.enable!(:va_notify_sms)}
      after{FeatureToggle.disable!(:va_notify_sms)}
      subject (:job) {SendNotificationJob.perform_later(send_sms_notification)}
      it {is_expected.to eq (SendNotificationJob.perform_later(send_sms_notification))}
  end    

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(SendNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { SendNotificationJob.perform_later(message) }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        allow(VANotifyService).to receive(:send_notifications) { bad_response }
        allow(VANotifyService).to receive(:send_notifications)
          .with(
            participant_id,
            appeal_id,
            email_template_id,
            appeal_status
          )
        perform_enqueued_jobs do
          result = SendNotificationJob.perform_later(message)
          expect(result.arguments[0]).to eq(message)
        end
      end

      it "makes audit params" do
        allow(VANotifyService).to receive(:send_notifications) { bad_response }
        allow(VANotifyService).to receive(:send_notifications)
          .with(
            participant_id,
            appeal_id,
            email_template_id,
            appeal_status
          )
        audit_creation_params = {
          message: message,
          good_response: good_response,
          notification_events_id: notification_events_id,
          notification_type: notification_type
        }
        allow_any_instance_of(SendNotificationJob)
          .to receive(:audit_params) { audit_creation_params }
        allow_any_instance_of(SendNotificationJob)
          .to receive(:audit_params)
          .with(message, good_response, notification_events_id, notification_type)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end
    end

    describe "handling errors" do
      it "retries on internal server error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "retries on not found error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyNotFoundError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "retries on rate limit error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyRateLimitError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "discards on unauthorized error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyUnauthorizedError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "discards on forbidden error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyForbiddenError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "returns error for fakes" do
        allow(VANotifyService).to receive(:send_notifications) { bad_response }
        allow(VANotifyService).to receive(:send_notifications)
          .with(
            bad_participant_id,
            appeal_id,
            email_template_id,
            appeal_status
          )
        expect(Rails.logger).to receive(:error).with(/Failed with error:/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end

      it "retries on retriable error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect_any_instance_of(SendNotificationJob).to receive(:retry_job)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(message)
        end
      end
    end
  end
end
