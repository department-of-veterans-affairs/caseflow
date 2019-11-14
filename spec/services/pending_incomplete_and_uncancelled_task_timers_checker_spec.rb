# frozen_string_literal: true

RSpec.describe PendingIncompleteAndUncancelledTaskTimersChecker do

  # Create Task Time which should qualify
  let(:task) { create(:generic_task, :on_hold) }
  let(:task_timer) { TaskTimer.create!(task: task)}

  before do
    created_at = 5.days.ago
    submitted_at = 6.days.ago

    task_timer.update!(created_at: created_at, submitted_at: submitted_at, canceled_at: null, processed_at: null)
  end

  it "sends a message to Slack when there are pending incomplete and uncancelled Task Timers" do

    checker = PendingIncompleteAndUncancelledTaskTimersChecker.new
    checker.call

    expect(checker.report?).to eq(True)
    expect(checker.report).to contains("1 pending and incomplete")
    expect(checker.slack_channel).to eq("appeals-queue-alerts")

    # see whether SlackService received message
  end
end
