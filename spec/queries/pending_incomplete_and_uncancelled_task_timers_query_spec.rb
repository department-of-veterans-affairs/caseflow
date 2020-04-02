# frozen_string_literal: true

describe PendingIncompleteAndUncancelledTaskTimersQuery do
  describe "#call" do
    let(:task) { create(:task) }
    let!(:task_timer) do
      create(:task_timer, task: task, created_at: 5.days.ago, submitted_at: 6.days.ago)
    end
    let!(:task_timer2) do
      create(:task_timer, task: task)
    end

    it "finds incomplete task timers" do
      expect(subject.call).to eq([task_timer])
    end
  end
end
