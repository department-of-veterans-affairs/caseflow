# frozen_string_literal: true

describe DispatchStats, :postgres do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  let(:monthly_stats) { Rails.cache.read("DispatchStats-2016-2") }
  let(:weekly_stats) { Rails.cache.read("DispatchStats-2016-w07") }
  let(:daily_stats) { Rails.cache.read("DispatchStats-2016-2-17") }
  let(:hourly_stats) { Rails.cache.read("DispatchStats-2016-2-17-15") }
  let(:prev_weekly_stats) { Rails.cache.read("DispatchStats-2016-w06") }

  context ".throttled_calculate_all!" do
    subject { DispatchStats.throttled_calculate_all! }
    context "when not previously calculated" do
      it "calculates stats" do
        expect(DispatchStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("DispatchStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated more than 61 minutes ago" do
      before { Rails.cache.write("DispatchStats-last-calculated-timestamp", 61.minutes.ago.to_i) }

      it "calculates stats" do
        expect(DispatchStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("DispatchStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated less than 60 minutes ago" do
      before { Rails.cache.write("DispatchStats-last-calculated-timestamp", 59.minutes.ago.to_i) }

      it "doesn't recalculate stats" do
        expect(DispatchStats).to_not receive(:calculate_all!)
        subject
      end
    end
  end

  context ".calculate_all!" do
    it "calculates and saves all completed dispatch_stats" do
      Generators::EstablishClaim.create(completed_at: 40.days.ago)
      Generators::EstablishClaim.create(completed_at: 7.days.ago)
      Generators::EstablishClaim.create(completed_at: 2.days.ago)
      Generators::EstablishClaim.create(completed_at: 4.hours.ago)
      Generators::EstablishClaim.create(completed_at: 30.minutes.ago)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_completed]).to eq(4)
      expect(weekly_stats[:establish_claim_completed]).to eq(3)
      expect(daily_stats[:establish_claim_completed]).to eq(2)
      expect(hourly_stats[:establish_claim_completed]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_completed]).to eq(1)
    end

    it "calculates and saves all started dispatch_stats" do
      Generators::EstablishClaim.create(started_at: 40.days.ago)
      Generators::EstablishClaim.create(started_at: 7.days.ago)
      Generators::EstablishClaim.create(started_at: 2.days.ago)
      Generators::EstablishClaim.create(started_at: 4.hours.ago)
      Generators::EstablishClaim.create(started_at: 30.minutes.ago)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_started]).to eq(4)
      expect(weekly_stats[:establish_claim_started]).to eq(3)
      expect(daily_stats[:establish_claim_started]).to eq(2)
      expect(hourly_stats[:establish_claim_started]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_started]).to eq(1)
    end

    it "calculates and saves all canceled dispatch_stats" do
      Generators::EstablishClaim.create(completed_at: 30.minutes.ago, completion_status: 1)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_canceled]).to eq(1)
      expect(weekly_stats[:establish_claim_canceled]).to eq(1)
      expect(daily_stats[:establish_claim_canceled]).to eq(1)
      expect(hourly_stats[:establish_claim_canceled]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_canceled]).to eq(0)
    end

    it "filters remands and partial grants from full grants" do
      remand = Generators::EstablishClaim.create(completed_at: 7.days.ago)
      full_grant = Generators::EstablishClaim.create(completed_at: 7.days.ago)
      ClaimEstablishment.create(task_id: remand.id, decision_type: 3)
      ClaimEstablishment.create(task_id: full_grant.id, decision_type: 1)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_full_grant_completed]).to eq(1)
      expect(monthly_stats[:establish_claim_partial_grant_remand_completed]).to eq(1)
    end
  end
end
