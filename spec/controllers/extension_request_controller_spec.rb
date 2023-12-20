# frozen_string_literal: true

RSpec.describe ExtensionRequestController, :postgres, type: :controller do
  describe "POST tasks/:id/extension_request" do
    let(:user) { create(:user).tap { |cavc_user| CavcLitigationSupport.singleton.add_user(cavc_user) } }

    let(:response_window_task) { create(:cavc_remand_processed_letter_response_window_task) }
    let(:task_id) { response_window_task.id }
    let(:days_on_hold) { 30 }
    let(:instructions) { ["Placing task on hold for 30 days"] }
    let(:params) { { decision: decision, days_on_hold: days_on_hold, instructions: instructions } }

    subject { post(:create, params: { task_id: task_id, task: params }) }

    before do
      User.authenticate!(user: user)
    end

    context "with a non-existent decision type" do
      let(:decision) { "undecided" }

      it "returns an error" do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context "when the decision is grant" do
      let!(:decision) { "grant" }

      context "with a non-cavc user" do
        let(:user) { create(:user) }

        it "returns an error" do
          subject

          expect(response.status).to eq(403)
        end
      end

      context "with the correct parameters" do
        it "creates the TimedHoldTask for the task and records the extension request grant" do
          subject
          expect(response.status).to eq(200)

          expect(response_window_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
          expect(response_window_task.children.count).to eq(2)

          extension_request_task = response_window_task.children.find_by(type: CavcGrantedExtensionRequestTask.name)
          expect(extension_request_task.label).to eq COPY::CAVC_GRANTED_EXTENSION_TASK_LABEL
          expect(extension_request_task.instructions).to eq(instructions)
          expect(extension_request_task.assigned_by).to eq(user)
          expect(extension_request_task.assigned_to).to eq(user)
          expect(extension_request_task.status).to eq(Constants.TASK_STATUSES.completed)

          timed_hold_task = response_window_task.children.find_by(type: TimedHoldTask.name)
          expect(timed_hold_task.instructions).to eq(instructions)
          expect(timed_hold_task.assigned_by).to eq(user)
          expect(timed_hold_task.timer_end_time.to_date).to eq((Time.zone.now + days_on_hold.days).to_date)
          expect(timed_hold_task.status).to eq(Constants.TASK_STATUSES.assigned)
        end
      end
    end

    context "when the decision is deny" do
      let!(:decision) { "deny" }

      it "record the extension request denial" do
        subject

        expect(response.status).to eq(200)

        expect(response_window_task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(response_window_task.children.count).to eq(1)

        extension_request_task = response_window_task.children.first
        expect(extension_request_task).to be_a(CavcDeniedExtensionRequestTask)
        expect(extension_request_task.label).to eq COPY::CAVC_DENIED_EXTENSION_TASK_LABEL
        expect(extension_request_task.instructions).to eq(instructions)
        expect(extension_request_task.assigned_by).to eq(user)
        expect(extension_request_task.assigned_to).to eq(user)
        expect(extension_request_task.status).to eq(Constants.TASK_STATUSES.completed)
      end
    end
  end
end
