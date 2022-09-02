# frozen_string_literal: true

describe SendNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  # rubocop:disable Style/BlockDelimiters
  let(:good_template_name) { "Appeal docketed" }
  let(:error_template_name) { "No Participant Id" }
  let(:success_status) { "Success" }
  let(:error_status) { "No participant_id" }
  let(:success_message_attributes) {
    {
      participant_id: "1234567890",
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
  let(:good_message) { VANotifySendMessageTemplate.new(success_message_attributes, good_template_name) }
  let(:bad_message) { VANotifySendMessageTemplate.new(error_message_attributes, error_template_name) }
  let(:participant_id) { success_message_attributes[:participant_id] }
  let(:bad_participant_id) { "123" }
  let(:appeal_id) { success_message_attributes[:appeal_id] }
  let(:email_template_id) { "d78cdba9-f02f-43dd-ab89-3ce42cc88078" }
  # let(:appeal_status) { "" }
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

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(SendNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { SendNotificationJob.perform_later(good_message.as_json) }
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
            # appeal_status
          )
        perform_enqueued_jobs do
          result = SendNotificationJob.perform_later(good_message.as_json)
          byebug
          expect(result.arguments[0]).to eq(good_message)
        end
      end

      # it "makes audit params" do
      #   allow(VANotifyService).to receive(:send_notifications) { bad_response }
      #   allow(VANotifyService).to receive(:send_notifications)
      #     .with(
      #       participant_id,
      #       appeal_id,
      #       email_template_id,
      #       appeal_status
      #     )
      #   audit_creation_params = {
      #     message: message,
      #     good_response: good_response,
      #     notification_events_id: notification_events_id,
      #     notification_type: notification_type
      #   }
      #   allow_any_instance_of(SendNotificationJob)
      #     .to receive(:audit_params) { audit_creation_params }
      #   allow_any_instance_of(SendNotificationJob)
      #     .to receive(:audit_params)
      #     .with(message, good_response, notification_events_id, notification_type)
      #   perform_enqueued_jobs do
      #     SendNotificationJob.perform_later(message)
      #   end
      # end
    end

    describe "handling errors" do
      it "retries on internal server error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.as_json)
        end
      end

      it "retries on not found error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyNotFoundError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.as_json)
        end
      end

      it "retries on rate limit error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyRateLimitError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.as_json)
        end
      end

      it "discards on unauthorized error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyUnauthorizedError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.as_json)
        end
      end

      it "discards on forbidden error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyForbiddenError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.as_json)
        end
      end

      # it "returns error for fakes" do
      #   allow(VANotifyService).to receive(:send_notifications) { bad_response }
      #   allow(VANotifyService).to receive(:send_notifications)
      #     .with(
      #       bad_participant_id,
      #       appeal_id,
      #       email_template_id,
      #       appeal_status
      #     )
      #   expect(Rails.logger).to receive(:error).with(/Failed with error:/)
      #   perform_enqueued_jobs do
      #     SendNotificationJob.perform_later(message)
      #   end
      # end

      it "retries on retriable error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect_any_instance_of(SendNotificationJob).to receive(:retry_job)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(good_message.as_json)
        end
      end
    end
  end
end
