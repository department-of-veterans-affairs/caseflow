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
  # rubocop:enable Style/BlockDelimiters

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(SendNotificationJob.new.queue_name).to eq("caseflow_test_send_notifications")
  end

  context ".perform" do
    subject(:job) { SendNotificationJob.perform_later(message) }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

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
    end
  end
end
