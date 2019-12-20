# frozen_string_literal: true

describe TaskTimer, :postgres do
  describe "processing" do
    before do
      Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    end

    it "becomes eligible to attempt in the future" do
      expect(TaskTimer.requires_processing.count).to eq 0

      task = create(:ama_task, :on_hold)
      TaskTimer.new(task: task).submit_for_processing!(delay: Time.zone.now + 24.hours)

      expect(TaskTimer.requires_processing.count).to eq 0

      Timecop.travel(Time.zone.now + 1.day + 1.minute) do
        expect(TaskTimer.requires_processing.count).to eq 1
      end
    end
  end

  describe "requires_processing" do
    let(:task) { create(:ama_task, trait) }
    let!(:task_timer) { TaskTimer.create!(task: task).tap(&:submit_for_processing!) }

    before do
      allow(TaskTimer).to receive(:processing_retry_interval_hours).and_return(0)
    end

    subject { TaskTimer.requires_processing }

    context "when the related task is closed" do
      let(:trait) { :cancelled }
      it "returns no task timers" do
        expect(subject.length).to eq(0)
      end
    end

    context "when the related task is active" do
      let(:trait) { :in_progress }
      it "returns the correct task timer" do
        processable_task_timers = subject
        expect(processable_task_timers.length).to eq(1)
        expect(processable_task_timers.first).to eq(task_timer)
      end
    end
  end
end
