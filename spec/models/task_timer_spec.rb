describe TaskTimer do
  describe "processing" do
    it "becomes eligible to attempt in the future" do
      expect(TaskTimer.requires_processing.count).to eq 0

      task = create(:generic_task, :on_hold)
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + 24.hours)

      expect(TaskTimer.requires_processing.count).to eq 0

      Timecop.travel(Time.zone.now + 1.day) do
        expect(TaskTimer.requires_processing.count).to eq 1
      end
    end
  end
end
