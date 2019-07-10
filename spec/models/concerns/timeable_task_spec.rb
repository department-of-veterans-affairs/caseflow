# frozen_string_literal: true

require "rails_helper"

describe TimeableTask do
  NOW = Time.utc(2018, 4, 24, 12, 0, 0)

  class SomeTimedTask < GenericTask
    include TimeableTask

    def when_timer_ends; end

    def timer_ends_at
      NOW + 5.days
    end
  end

  class AnotherTimedTask < GenericTask
    include TimeableTask

    def timer_ends_at; end
  end

  class OldTimedTask < GenericTask
    include TimeableTask

    def when_timer_ends; end

    def timer_ends_at
      NOW - 5.days
    end
  end

  before do
    Timecop.freeze(NOW)
  end

  let(:appeal) { create(:appeal, receipt_date: 10.days.ago) }

  it "creates a task timer with the correct delay when we create some timed task" do
    task = SomeTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton)
    timers = TaskTimer.where(task: task)
    expect(timers.length).to eq(1)
    delayed_start = Time.zone.now + 5.days - 3.hours + 1.minute
    expect(timers.first.last_submitted_at).to eq(delayed_start)
    expect(timers.first.submitted_at).to eq(delayed_start)
  end

  it "queues itself when the delay is in the past" do
    task = OldTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton)
    timers = TaskTimer.where(task: task)
    expect(timers.length).to eq(1)
    expect(timers.first.submitted_and_ready?).to eq(true)
    expect(timers.first.last_submitted_at).to eq(NOW)
    delay_in_the_past = Time.zone.now - 5.days - 3.hours + 1.minute
    expect(timers.first.submitted_at).to eq(delay_in_the_past)
  end

  context "when not correctly configured" do
    subject { AnotherTimedTask.create!(appeal: appeal, assigned_to: Bva.singleton) }

    it "errors if we do not pass a timer delay" do
      expect { subject }.to raise_error(Caseflow::Error::MissingTimerMethod)
    end
  end
end
