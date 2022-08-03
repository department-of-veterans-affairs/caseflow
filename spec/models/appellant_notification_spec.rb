# frozen_string_literal: true

require "appellant_notification.rb"

# describe AppellantNotification do
#   describe AppellantNotification::AppealDocketed do
#     describe ".distribution_task" do
#       let(:appeal) { create(:appeal, :with_pre_docket_task) }
#       let(:task_factory) do
#         InitialTasksFactory.prepend(AppellantNotification::AppealDocketed)
#         InitialTasksFactory.new(appeal)
#       end
#       it "will notify appellant when an appeal is docketed" do
#         task_factory.distribution_task
#         sleep(1)
#         expect(Shoryuken::Client.sqs.receive_message(
#                  queue_url: "http://localhost:4576/000000000000/caseflow_development_send_notifications"
#                )).to eq("Bob")
#       end
#     end
#   end
# end

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





describe AppellantNotification do
  describe "self.handle_errors" do
    let!(:appeal) { create(:appeal, number_of_claimants: 1) }
    describe "with no claimant listed" do
      let!(:appeal) { create(:appeal, number_of_claimants: 0) }
      it "raises" do
        expect { AppellantNotification.handle_errors(appeal) }.to raise_error(AppellantNotification::NoClaimantError)
      end
    end
    describe "with no participant_id listed" do
      let(:claimant) { create(:claimant, participant_id: "") }
      let!(:appeal) { create(:appeal) }
      it "raises" do
        expect { 
          appeal.claimants = [claimant]
          AppellantNotification.handle_errors(appeal) 
        }.to raise_error(AppellantNotification::NoParticipantIdError)
      end
    end
    describe "with no errors" do
      it "doesn't raise" do
        expect { AppellantNotification.handle_errors(appeal) }.not_to raise_error
      end
    end
  end
end