require "rails_helper"

describe IntakeStats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  context ".throttled_calculate_all!" do
    subject { IntakeStats.throttled_calculate_all! }
    context "when not previously calculated" do
      it "calculates stats" do
        expect(IntakeStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("IntakeStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated more than 20 minutes ago" do
      before { Rails.cache.write("IntakeStats-last-calculated-timestamp", 21.minutes.ago.to_i) }

      it "calculates stats" do
        expect(IntakeStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("IntakeStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated less than 20 minutes ago" do
      before { Rails.cache.write("IntakeStats-last-calculated-timestamp", 19.minutes.ago.to_i) }

      it "doesn't recalculate stats" do
        expect(IntakeStats).to_not receive(:calculate_all!)
        subject
      end
    end
  end
end
