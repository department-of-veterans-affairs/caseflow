# frozen_string_literal: true

require "appellant_notification.rb"

def test_perform_enqueued_jobs
    perform_enqueued_jobs do
        Shoryuken::Client.queues("caseflow_development_send_notifications").send_message(message_body: msg_bdy).perform_later(1,2,3)
    end
    assert_performed_jobs 1
end
require "models/appellant_notification.rb"

describe AppellantNotification do
  describe AppellantNotification::AppealDocketed do
    describe ".distribution_task" do
      let(:appeal) { create(:appeal, :with_pre_docket_task) }
      let(:task_factory) do
        InitialTasksFactory.prepend(AppellantNotification::AppealDocketed)
        InitialTasksFactory.new(appeal)
      end
      it "will notify appellant when an appeal is docketed" do
        task_factory.distribution_task
        sleep(1)
        # expect.to receive(:notify_appellant)
        expect(Shoryuken::Client.sqs.receive_message(
                 queue_url: "http://localhost:4576/000000000000/caseflow_development_send_notifications"
               )).to eq("Bob")
      end
    end
  end
end

# describe AppellantNotification::AppealDocketed do
#   describe ".distribution_task" do
#     let(:appeal) { create(:appeal, :with_pre_docket_task) }
#     let(:spaghetti) do
#       InitialTasksFactory.prepend(AppellantNotification::AppealDocketed)
#       InitialTasksFactory.new(appeal)
#     end
#     it "will notify appellant when an appeal is docketed" do
#       spaghetti.distribution_task
#       expect(appeal.tasks.any? {|t| t.type == "DistributionTask"}).to eq true
#     end
#   end
# end
