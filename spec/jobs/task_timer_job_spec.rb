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
  end

  it "handles errors arising from task objects and continues processing succesful timers" do
    error_timer = timer_for_task_that_errors
    timer = timer_for_task
    Timecop.travel(Time.zone.now + 1.day)

    expect(TaskTimer.requires_processing.include?(error_timer)).to eq(true)

    TaskTimerJob.perform_now

    expect(timer.reload.processed_at).not_to eq(nil)
    expect(error_timer.reload.processed_at).to eq(nil)
  end
end
