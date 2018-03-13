describe TakeDocketSnapshotJob do
  context ".perform" do
    it "creates a new snapshot and tracers" do
      expect(DocketSnapshot.count).to eq(0)
      expect(DocketTracer.count).to eq(0)
      TakeDocketSnapshotJob.perform_now
      expect(DocketSnapshot.count).to eq(1)
      expect(DocketTracer.count).to eq(13)
    end
  end
end
