describe TaskTimerJob do
  class TimedTask < GenericTask
    include TimeableTask

    def when_timer_ends; end

    def self.timer_delay
      1.day
    end
  end

  before do
    Timecop.freeze(Time.zone.today)
  end

  after do
    Timecop.return
  end

  it "processes jobs only if they aren't already processed" do
    task = TimedTask.create!(appeal: create(:appeal), assigned_to: Bva.singleton)
    timer = TaskTimer.find_by(task: task)

    Timecop.travel(Time.zone.now + 1.day)
    TaskTimerJob.perform_now
    processed_at = timer.reload.processed_at

    Timecop.travel(Time.zone.now + 1.day)
    TaskTimerJob.new.process(timer)

    # ensure the "processed at" field wasn't updated a second time
    expect(timer.reload.processed_at).to eq(processed_at)
  end
end
