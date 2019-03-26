# frozen_string_literal: true

describe TaskTimer do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  describe "processing" do
    it "becomes eligible to attempt in the future" do
      expect(TaskTimer.requires_processing.count).to eq 0

      task = create(:generic_task, :on_hold)
      TaskTimer.new(task: task).submit_for_processing!(delay: Time.zone.now + 24.hours)

      expect(TaskTimer.requires_processing.count).to eq 0

      Timecop.travel(Time.zone.now + 1.day + 1.minute) do
        expect(TaskTimer.requires_processing.count).to eq 1
      end
    end
  end
end
