describe SyncReviewsJob do
  context ".perform" do
    let!(:end_product_establishment_more_recently_synced) do
      create(:end_product_establishment, last_synced_at: 1.day.ago, established_at: 4.days.ago)
    end

    let!(:end_product_establishment_less_recently_synced) do
      create(:end_product_establishment, last_synced_at: 2.days.ago, established_at: 4.days.ago)
    end

    let!(:end_product_establishment_never_synced) do
      create(:end_product_establishment, last_synced_at: nil, established_at: 4.days.ago)
    end

    context "when there are canceled or cleared end product establishments" do
      let!(:end_product_establishment_canceled) do
        create(:end_product_establishment, :canceled, established_at: 4.days.ago)
      end

      let!(:end_product_establishment_cleared) do
        create(:end_product_establishment, :cleared, established_at: 4.days.ago)
      end

      it "does not sync them" do
        expect(EndProductSyncJob).to_not receive(:perform_later).with(end_product_establishment_canceled.id)
        expect(EndProductSyncJob).to_not receive(:perform_later).with(end_product_establishment_cleared.id)

        SyncReviewsJob.perform_now("limit" => 2)
      end
    end

    it "prioritizes never synced ramp elections" do
      expect(EndProductSyncJob).to receive(:perform_later).once.with(end_product_establishment_never_synced.id)
      SyncReviewsJob.perform_now("limit" => 1)
    end

    it "prioritizes less recently synced ramp_elections" do
      expect(EndProductSyncJob).to receive(:perform_later).with(end_product_establishment_never_synced.id)
      expect(EndProductSyncJob).to receive(:perform_later).with(end_product_establishment_less_recently_synced.id)

      SyncReviewsJob.perform_now("limit" => 2)
    end
  end
end
