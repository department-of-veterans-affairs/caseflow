require "rails_helper"

describe DispatchStats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  let(:monthly_stats) { Rails.cache.read("stats-2016-2") }
  let(:weekly_stats) { Rails.cache.read("stats-2016-w07") }
  let(:daily_stats) { Rails.cache.read("stats-2016-2-17") }
  let(:hourly_stats) { Rails.cache.read("stats-2016-2-17-15") }
  let(:prev_weekly_stats) { Rails.cache.read("stats-2016-w06") }

  let!(:appeal_1) { Appeal.create(vacols_id: "123C") }
  let!(:appeal_2) { Appeal.create(vacols_id: "456C") }
  let!(:appeal_3) { Appeal.create(vacols_id: "789C") }
  let!(:appeal_4) { Appeal.create(vacols_id: "123B") }
  let!(:appeal_5) { Appeal.create(vacols_id: "456B") }
  let!(:appeal_6) { Appeal.create(vacols_id: "789B") }

  context ".calculate_all!" do
    it "calculates and saves all completed dispatch_stats" do
      EstablishClaim.create(completed_at: 40.days.ago, appeal: appeal_1)
      EstablishClaim.create(completed_at: 7.days.ago, appeal: appeal_2)
      EstablishClaim.create(completed_at: 2.days.ago, appeal: appeal_3)
      EstablishClaim.create(completed_at: 4.hours.ago, appeal: appeal_4)
      EstablishClaim.create(completed_at: 30.minutes.ago, appeal: appeal_5)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_completed]).to eq(4)
      expect(weekly_stats[:establish_claim_completed]).to eq(3)
      expect(daily_stats[:establish_claim_completed]).to eq(2)
      expect(hourly_stats[:establish_claim_completed]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_completed]).to eq(1)
    end

    it "calculates and saves all started dispatch_stats" do
      EstablishClaim.create(started_at: 40.days.ago, appeal: appeal_1)
      EstablishClaim.create(started_at: 7.days.ago, appeal: appeal_2)
      EstablishClaim.create(started_at: 2.days.ago, appeal: appeal_3)
      EstablishClaim.create(started_at: 4.hours.ago, appeal: appeal_4)
      EstablishClaim.create(started_at: 30.minutes.ago, appeal: appeal_5)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_started]).to eq(4)
      expect(weekly_stats[:establish_claim_started]).to eq(3)
      expect(daily_stats[:establish_claim_started]).to eq(2)
      expect(hourly_stats[:establish_claim_started]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_started]).to eq(1)
    end

    it "calculates and saves all canceled dispatch_stats" do
      user = User.create(station_id: "ABC", css_id: "123", full_name: "Robert Smith")
      establish_claim = EstablishClaim.create(appeal: appeal_1)
      establish_claim.prepare!
      establish_claim.assign!(:assigned, user)
      establish_claim.start!
      establish_claim.cancel!

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_canceled]).to eq(1)
      expect(weekly_stats[:establish_claim_canceled]).to eq(1)
      expect(daily_stats[:establish_claim_canceled]).to eq(1)
      expect(hourly_stats[:establish_claim_canceled]).to eq(1)
      expect(prev_weekly_stats[:establish_claim_canceled]).to eq(0)
    end

    it "filters remands and partial grants from full grants" do
      remand = EstablishClaim.create(appeal: appeal_1, completed_at: 7.days.ago)
      full_grant = EstablishClaim.create(appeal: appeal_2, completed_at: 7.days.ago)
      ClaimEstablishment.create(task_id: remand.id, decision_type: 3)
      ClaimEstablishment.create(task_id: full_grant.id, decision_type: 1)

      DispatchStats.calculate_all!

      expect(monthly_stats[:establish_claim_full_grant_completed]).to eq(1)
      expect(monthly_stats[:establish_claim_partial_grant_remand_completed]).to eq(1)
    end

    it "overwrites incomplete periods" do
      EstablishClaim.create(completed_at: 30.minutes.ago, appeal: appeal_5)
      DispatchStats.calculate_all!
      EstablishClaim.create(completed_at: 1.minute.ago, appeal: appeal_6)
      DispatchStats.calculate_all!

      expect(hourly_stats[:establish_claim_completed]).to eq(2)
    end

    it "does not recalculate complete periods" do
      EstablishClaim.create(completed_at: 7.days.ago, appeal: appeal_5)
      DispatchStats.calculate_all!
      EstablishClaim.create(completed_at: 7.days.ago, appeal: appeal_6)
      DispatchStats.calculate_all!

      expect(prev_weekly_stats[:establish_claim_completed]).to eq(1)
    end
  end
end
