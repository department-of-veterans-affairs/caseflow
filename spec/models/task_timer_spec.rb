# frozen_string_literal: true

describe TaskTimer do
  describe "processing" do
    before do
      Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    end

    it "becomes eligible to attempt in the future" do
      expect(TaskTimer.requires_processing.count).to eq 0

      task = create(:generic_task, :on_hold)
      TaskTimer.new(task: task).submit_for_processing!(delay: Time.zone.now + 24.hours)

      expect(TaskTimer.requires_processing.count).to eq 0

      Timecop.travel(Time.zone.now + 1.day + 1.minute) do
        expect(TaskTimer.requires_processing.count).to eq 1
      end
    end
  end

  describe "requires_processing", focus: true do
    let(:task) { FactoryBot.create(:generic_task, status: task_status) }
    let(:task_timer) { TaskTimer.create!(task: task).tap(&:submit_for_processing!) }

    subject { task_timer.requires_processing }

    context "when the related task is closed" do
      let(:task_status) { Constants.TASK_STATUSES.cancelled }
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when the related task is active" do
      let(:task_status) { Constants.TASK_STATUSES.in_progress }
      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end
end
