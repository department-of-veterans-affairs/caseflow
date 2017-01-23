require "rails_helper"

describe Stats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  let(:monthly_stats) { Rails.cache.read("stats-2016-2") }
  let(:weekly_stats) { Rails.cache.read("stats-2016-w07") }
  let(:daily_stats) { Rails.cache.read("stats-2016-2-17") }
  let(:hourly_stats) { Rails.cache.read("stats-2016-2-17-15") }
  let(:prev_weekly_stats) { Rails.cache.read("stats-2016-w06") }

  context ".calculate_all!" do
    it "calculates and saves all calculated stats" do
      Certification.create(completed_at: 40.days.ago)
      Certification.create(completed_at: 7.days.ago)
      Certification.create(completed_at: 2.days.ago)
      Certification.create(completed_at: 4.hours.ago)
      Certification.create(completed_at: 30.minutes.ago)

      Stats.calculate_all!

      expect(monthly_stats[:certifications_completed]).to eq(4)
      expect(weekly_stats[:certifications_completed]).to eq(3)
      expect(daily_stats[:certifications_completed]).to eq(2)
      expect(hourly_stats[:certifications_completed]).to eq(1)
      expect(prev_weekly_stats[:certifications_completed]).to eq(1)
    end

    it "overwrites incomplete periods" do
      Certification.create(completed_at: 30.minutes.ago)
      Stats.calculate_all!
      Certification.create(completed_at: 1.minute.ago)
      Stats.calculate_all!

      expect(hourly_stats[:certifications_completed]).to eq(2)
    end

    it "does not recalculate complete periods" do
      Certification.create(completed_at: 7.days.ago)
      Stats.calculate_all!
      Certification.create(completed_at: 7.days.ago)
      Stats.calculate_all!

      expect(prev_weekly_stats[:certifications_completed]).to eq(1)
    end
  end
end
