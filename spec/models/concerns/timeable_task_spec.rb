# frozen_string_literal: true

describe TimeableTask, :postgres do
  let(:now) { Time.utc(2018, 4, 24, 12, 0, 0) }

  module CurrentDate
    def now
      Time.utc(2018, 4, 24, 12, 0, 0)
    end
  end

  class SomeTimedTask < Task
    include TimeableTask
    include CurrentDate

    def when_timer_ends; end

    def timer_ends_at
      now + 5.days
    end
  end

  class AnotherTimedTask < Task
    include TimeableTask

    def timer_ends_at; end
  end

  class OldTimedTask < Task
    include TimeableTask
    include CurrentDate

    def when_timer_ends; end

    def timer_ends_at
      now - 5.days
    end
  end

  class EdgeCaseTimedTask < Task
    include TimeableTask
    include CurrentDate

    def when_timer_ends; end

    def timer_ends_at
      # Our task timer job runs every hour. On occasion we create task timers that should have expired 3.99999 days ago
      # so they are not caught by the initial expired_without_processing? check when they are created. However, by the
      # time the job has run, the task should have expired 4.000001 days ago and falls out of our
      # expired_without_processing scope. See https://github.com/department-of-veterans-affairs/caseflow/issues/15245
      4.days.ago + 30.minutes
    end
  end

  before do
    Timecop.freeze(now)
  end

  let(:appeal) { create(:appeal, receipt_date: 10.days.ago) }

  it "creates a task timer with the correct delay when we create some timed task" do
    task = SomeTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton)
    timers = TaskTimer.where(task: task)
    expect(timers.length).to eq(1)

    delayed_start = Time.zone.now + 5.days - TaskTimer.processing_retry_interval_hours.hours + 1.minute

    expect(timers.first.last_submitted_at).to eq(delayed_start)
    expect(timers.first.submitted_at).to eq(task.timer_ends_at)
  end

  shared_examples "resets the timer" do
    it "queues itself immediately when the delay is in the past" do
      timers = TaskTimer.where(task: task)
      expect(timers.length).to eq(1)
      expect(timers.first.submitted_and_ready?).to eq(true)
      expect(timers.first.submitted_at).to eq(task.timer_ends_at)
      expect(timers.first.last_submitted_at).to eq(now)
    end
  end

  context "when the delay is in the past" do
    let(:task) { OldTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton) }

    it_behaves_like "resets the timer"
  end

  context "when the delay is judge barely less than four days in the past" do
    let(:task) { EdgeCaseTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton) }

    it_behaves_like "resets the timer"
  end

  context "when not correctly configured" do
    subject { AnotherTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton) }

    it "errors if we do not pass a timer delay" do
      expect { subject }.to raise_error(Caseflow::Error::MissingTimerMethod)
    end
  end
end
