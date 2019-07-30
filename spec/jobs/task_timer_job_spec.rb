# frozen_string_literal: true

require "rails_helper"

describe TaskTimerJob do
  class TimedTask < GenericTask
    include TimeableTask

    def when_timer_ends; end

    def timer_ends_at
      Time.zone.today + 1.day
    end
  end

  class TimedTaskThatErrors < GenericTask
    include TimeableTask

    def when_timer_ends
      fail
    end

    def timer_ends_at
      Time.zone.today + 1.day
    end
  end

  before do
    Timecop.freeze(Time.zone.today)
  end

  after do
    Timecop.return
  end

  let(:timer_for_task) do
    task = TimedTask.create!(appeal: create(:appeal), assigned_to: Bva.singleton)
    TaskTimer.find_by(task: task)
  end

  let(:timer_for_task_that_errors) do
    task = TimedTaskThatErrors.create!(appeal: create(:appeal), assigned_to: Bva.singleton)
    TaskTimer.find_by(task: task)
  end

  it "processes jobs only if they aren't already processed" do
    timer = timer_for_task
    Timecop.travel(Time.zone.now + 1.day)

    TaskTimerJob.perform_now
    processed_at = timer.reload.processed_at

    Timecop.travel(Time.zone.now + 1.day)
    TaskTimerJob.new.process(timer)

    # ensure the "processed at" field wasn't updated a second time
    expect(timer.reload.processed_at).to eq(processed_at)

    # ensure the "canceled at" field wasn't updated
    TaskTimerJob.new.cancel(timer)
    expect(timer.reload.canceled_at).to eq(nil)
  end

  it "handles errors arising from task objects and continues processing succesful timers" do
    error_timer = timer_for_task_that_errors
    timer = timer_for_task
    Timecop.travel(Time.zone.now + 1.day)

    expect(TaskTimer.requires_processing).to include error_timer

    TaskTimerJob.perform_now

    expect(timer.reload.processed_at).not_to be_nil
    expect(timer.reload.attempted_at).not_to be_nil
    expect(error_timer.reload.processed_at).to be_nil
    expect(error_timer.error).to eq("RuntimeError")
    expect(error_timer.attempted_at).to be_nil # because it was in a failed transaction
  end

  it "cancels jobs whose parent tasks are cancelled" do
    timer = timer_for_task

    # avoid the callbacks that cancel the timer from task close
    Timecop.travel(Time.zone.now + 1.day)
    timer.task.update_columns(status: Constants.TASK_STATUSES.cancelled)

    Timecop.travel(Time.zone.now + 1.day)
    TaskTimerJob.perform_now
    canceled_at = timer.reload.canceled_at
    expect(timer.reload.processed_at).to eq(nil)
    expect(timer.reload.canceled_at).not_to eq(nil)

    Timecop.travel(Time.zone.now + 1.day)
    TaskTimerJob.new.cancel(timer)
    expect(timer.reload.canceled_at).to eq(canceled_at)

    TaskTimerJob.new.process(timer)
    expect(timer.reload.processed_at).to eq(nil)
  end
end
