# frozen_string_literal: true

describe TaskTimerJob, :postgres do
  class TimedTask < Task
    include TimeableTask

    def when_timer_ends; end

    def timer_ends_at
      Time.zone.today + 1.day
    end
  end

  class TimedTaskThatErrors < Task
    include TimeableTask

    def when_timer_ends
      fail
    end

    def timer_ends_at
      Time.zone.today + 1.day
    end
  end

  let(:timer_for_task) do
    task = TimedTask.create!(appeal: create(:appeal), assigned_to: Bva.singleton)
    task_timer = TaskTimer.find_by(task: task)
    task_timer.update(last_submitted_at: 1.day.ago)
    task_timer.reload
  end

  let(:timer_for_task_that_errors) do
    task = TimedTaskThatErrors.create!(appeal: create(:appeal), assigned_to: Bva.singleton)
    task_timer = TaskTimer.find_by(task: task)
    task_timer.update(last_submitted_at: 1.day.ago)
    task_timer.reload
  end

  it "does not process timers that are already processed" do
    timer_for_task.update(processed_at: 1.day.ago, error: "some error")
    processed_at = timer_for_task.reload.processed_at

    TaskTimerJob.perform_now

    expect(timer_for_task.reload.processed_at).to eq processed_at
    expect(timer_for_task.canceled_at).to be_nil
    expect(timer_for_task.attempted_at).to be_nil
    expect(timer_for_task.error).to eq("some error")
  end

  it "does not process timers that are already canceled" do
    timer_for_task.update(canceled_at: 1.day.ago, error: "some error")
    canceled_at = timer_for_task.reload.canceled_at

    TaskTimerJob.perform_now

    expect(timer_for_task.reload.processed_at).to be_nil
    expect(timer_for_task.canceled_at).to eq canceled_at
    expect(timer_for_task.attempted_at).to be_nil
    expect(timer_for_task.error).to eq("some error")
  end

  it "handles errors arising from task objects and continues processing successful timers" do
    error_timer = timer_for_task_that_errors
    timer = timer_for_task

    TaskTimerJob.perform_now

    expect(timer.reload.processed_at).not_to be_nil
    expect(timer.attempted_at).not_to be_nil
    expect(timer.error).to be_nil
    expect(error_timer.reload.processed_at).to be_nil
    expect(error_timer.error).to eq("RuntimeError")
    expect(error_timer.attempted_at).to be_nil # because it was in a failed transaction
  end

  it "cancels timers whose parent tasks are closed" do
    timer = timer_for_task
    # avoid the callbacks that cancel the timer from task close
    timer.task.update_columns(status: Task.closed_statuses.sample)

    TaskTimerJob.perform_now

    expect(timer.reload.processed_at).to be_nil
    expect(timer.canceled_at).not_to be_nil
    expect(timer.processed_at).to be_nil
  end

  it "does not cancel processable timers whose parent tasks are not closed" do
    timer = timer_for_task
    # avoid the callbacks that cancel the timer from task close
    timer.task.update_columns(status: Task.open_statuses.sample)

    TaskTimerJob.perform_now

    expect(timer.reload.canceled_at).to be_nil
  end

  it "records the job's runtime with Datadog" do
    expect(DataDogService).to receive(:emit_gauge).with(
      app_name: "caseflow_job",
      metric_group: TaskTimerJob.name.underscore,
      metric_name: "runtime",
      metric_value: anything
    )

    TaskTimerJob.perform_now
  end
end
