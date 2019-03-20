# frozen_string_literal: true

describe TimedHoldTask do
  let(:appeal) { create(:appeal) }
  let(:user) { create(:user) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:params) { { assigned_to: user, parent: root_task, appeal: root_task.appeal } }

  context "on hold duration" do
    it "must have a value between 1 and 100" do
      expect { TimedHoldTask.create!(params.merge(on_hold_duration: 0)) }.to raise_error(ActiveRecord::RecordInvalid)
      expect { TimedHoldTask.create!(params.merge(on_hold_duration: 10)) }.not_to raise_error
    end
  end

  context "when timer ends" do
    it "completes timed hold task" do
      task = TimedHoldTask.create!(params.merge(on_hold_duration: 10))
      expect(task.status).to eq("assigned")
      task.when_timer_ends
      expect(task.reload.status).to eq("completed")
    end
  end
end
