# frozen_string_literal: true

describe PendingIncompleteAndUncancelledTaskTimersChecker do
  describe "#call" do
    let(:task) { create(:task) }
    let!(:task_timer) do
      create(:task_timer, task: task, created_at: 5.days.ago, submitted_at: 6.days.ago)
    end
    let!(:task_timer2) { create(:task_timer, task: task) }

    it "sends a message to Slack when there are pending incomplete and uncancelled Task Timers" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match("1 pending and incomplete")
    end
  end
end
