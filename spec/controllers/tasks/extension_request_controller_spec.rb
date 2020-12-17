# frozen_string_literal: true

RSpec.describe Tasks::ExtensionRequestController, :postgres, type: :controller do
  describe "POST tasks/:id/extension_request" do
    let(:user) { create(:user) }

    let(:response_window_task) { create(:ama_task) }
    let(:task_id) { response_window_task.id }
    let(:days_on_hold) { 30 }
    let(:instructions) { "Placing task on hold for 30 days" }
    let(:params) { { decision: decision, days_on_hold: days_on_hold, instructions: instructions } }

    subject { post(:create, params: { task_id: task_id, task: params }) }

    before do
      User.authenticate!(user: user)
    end

    context "when the decision is grant" do
      let!(:decision) { "grant" }

      context "with the correct parameters" do
        it "creates the TimedHoldTask for the task and records the extension request grant" do
          subject
          expect(response.status).to eq(200)

          # TODO: check for extension request grant

          expect(response_window_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
          timed_hold_task = response_window_task.children.first
          expect(timed_hold_task).to be_a(TimedHoldTask)
          expect(timed_hold_task.instructions).to eq([instructions])
          expect(timed_hold_task.assigned_by).to eq(user)
          expect(timed_hold_task.timer_end_time.to_date).to eq((Time.zone.now + days_on_hold.days).to_date)
        end
      end

      context "with a non-existent task_id" do
        let(:task_id) { response_window_task.id + 999 }

        it "returns an error" do
          subject

          expect(response.status).to eq(404)
        end
      end
    end

    context "when the decision is grant" do
      let!(:decision) { "grant" }

      it "record the extension request denial" do
        subject

        expect(response.status).to eq(200)

        # TODO: check for extension request denial
      end
    end
  end
end
