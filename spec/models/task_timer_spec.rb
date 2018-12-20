describe TaskTimer do
  describe "#process_after" do
    it "becomes eligible to attempt in the future" do
      expect(TaskTimer.requires_processing.count).to eq 0

      task = create(:generic_task, :on_hold)
      task_timer = TaskTimer.create!(task: task)
      task_timer.process_after(Time.zone.now + 24.hours)

      expect(TaskTimer.requires_processing.count).to eq 0

      Timecop.travel(Time.zone.now + 1.day) do
        expect(TaskTimer.requires_processing.count).to eq 1
      end
    end
  end
end
