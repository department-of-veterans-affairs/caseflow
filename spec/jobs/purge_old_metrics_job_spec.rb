describe PurgeOldMetricsJob do
  include ActiveJob::TestHelper
  describe "#perform" do
    subject { PurgeOldMetricsJob.new.perform }

    it "removes expected metrics" do
      allow_any_instance_of(PurgeOldMetricsJob).to receive(:purge_end_date).and_return("2024-03-13")

      old_metric = create(:metric, created_at: Time.zone.parse("2024-03-12"))
      new_metric = create(:metric, created_at: Time.zone.parse("2024-03-13"))

      subject

      metrics = Metric.all
      expect(metrics).to include(new_metric)
      expect(metrics).to_not include(old_metric)
    end
  end
end