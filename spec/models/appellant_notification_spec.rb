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
    let(:appeal) { create(:appeal, number_of_claimants: 1) }

    context "if appeal is nil" do
      let (:empty_appeal) {}
      it "reports the error" do
        expect(AppellantNotification).not_to receive(AppellantNotification.notify_appellant)
        # ???
      end
    end

    context "with no claimant listed" do
      let(:appeal) { create(:appeal, number_of_claimants: 0) }
      it "returns error message" do
        expect(AppellantNotification.handle_errors(appeal)).to eq AppellantNotification::NoClaimantError.new(appeal.id).message
        # raise_error(AppellantNotification::NoClaimantError)
      end
    end

    context "with no participant_id listed" do
      let(:claimant) { create(:claimant, participant_id: "") }
      let(:appeal) { create(:appeal) }
      before do
        appeal.claimants = [claimant]
      end
      it "returns error message" do
        expect(AppellantNotification.handle_errors(appeal)).to eq AppellantNotification::NoParticipantIdError.new(appeal.id).message
      end
    end
      
    context "with no errors" do
      it "doesn't raise" do
        expect(AppellantNotification.handle_errors(appeal)).to eq "Success"
      end
    end
  end

  describe "self.create_payload" do 
    let(:good_appeal) { create(:appeal, number_of_claimants: 1) }
    let(:bad_appeal) { create(:appeal) }
    let(:bad_claimant) { create(:claimant, participant_id: "") }
    let(:template_name) { "test" }
    context "creates a payload with no exceptions" do
      it "has a status value of success" do
        # I want to check that msg_bdy contains the success status from handle_errors
        expect(AppellantNotification.create_payload(good_appeal, template_name)[:message_attributes][:status][:value]).to eq "Success"
      end
    end
    context "creates a payload with exceptions" do
      before do
        bad_appeal.claimants = [bad_claimant]
      end
      it "does not have a success status" do
        expect(AppellantNotification.create_payload(bad_appeal, template_name)[:message_attributes][:status][:value]).not_to eq "Success"
      end
    end
  end

  describe "self.notify_appellant" do
    let(:appeal) { create(:appeal, number_of_claimants: 1) }
    let(:template_name) { "test" }
    context "sends message to shoryuken" do
      it "sends the payload" do
        queue = double('queue')
        expect(queue).to receive(:send_message).with(AppellantNotification.create_payload(appeal,template_name))
        AppellantNotification.notify_appellant(appeal, template_name, queue)
      end
    end
  end
end
