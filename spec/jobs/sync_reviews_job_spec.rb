describe SyncReviewsJob do
  context ".perform", focus: true do
    let!(:ramp_election_more_recently_synced) do
      create(:ramp_election, :established, end_product_status_last_synced_at: 1.day.ago)
    end

    let!(:ramp_election_less_recently_synced) do
      create(:ramp_election, :established, end_product_status_last_synced_at: 2.days.ago)
    end

    let!(:ramp_election_never_synced) do
      create(:ramp_election, :established, end_product_status_last_synced_at: nil)
    end

    it "prioritizes never synced ramp elections" do
      expect(RampElectionSyncJob).to receive(:perform_later).once.with(ramp_election_never_synced.id)

      SyncReviewsJob.perform_now("limit" => 1)
    end

    it "prioritizes less recently synced ramp_elections" do
      expect(RampElectionSyncJob).to receive(:perform_later).with(ramp_election_never_synced.id)
      expect(RampElectionSyncJob).to receive(:perform_later).with(ramp_election_less_recently_synced.id)

      SyncReviewsJob.perform_now("limit" => 2)
    end
  end
end
