# frozen_string_literal: true

describe TakeDocketSnapshotJob, :all_dbs do
  before do
    allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
    allow(AppealRepository).to receive(:docket_counts_by_month) do
      (1.year.ago.to_date..Time.zone.today).map { |d| Date.new(d.year, d.month, 1) }.uniq.each_with_index.map do |d, i|
        {
          "year" => d.year,
          "month" => d.month,
          "cumsum_n" => i * 10_000 + 3456,
          "cumsum_ready_n" => i * 5000 + 3456
        }
      end
    end
  end

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
