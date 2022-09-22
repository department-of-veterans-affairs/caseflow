# frozen_string_literal: true

describe VANotifyStatusUpdateJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:notifications_email_only) do
    FactoryBot.create_list :notification_email_only, 10
  end
  let(:notifications_sms_only) do
    FactoryBot.create_list :notification_sms_only, 10
  end
  let(:notifications_email_and_sms) do
    FactoryBot.create_list :notification_email_and_sms, 10
  end
  let(:queue_name) { "caseflow_test_low_priority" }

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(VANotifyStatusUpdateJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        perform_enqueued_jobs do
          result = VANotifyStatusUpdateJob.perform_later
          expect(result.arguments[0]).to eq(nil)
        end
      end

      it "sends to VA Notify when no errors are present" do
        expect(Rails.logger).not_to receive(:error)
        expect { VANotifyStatusUpdateJob.perform_now.to receive(:send_to_va_notify) }
      end
    end
  end
end