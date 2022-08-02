# frozen_string_literal: true

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
