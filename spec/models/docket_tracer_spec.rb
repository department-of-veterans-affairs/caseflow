# frozen_string_literal: true

describe DocketSnapshot, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  before do
    allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
    allow(AppealRepository).to receive(:regular_non_aod_docket_count) { 123_456 }
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

  let(:snapshot) { DocketSnapshot.create }
  let(:first_tracer) { snapshot.docket_tracers.first }
  let(:second_tracer) { snapshot.docket_tracers.second }
  let(:last_tracer) { snapshot.docket_tracers.last }

  context "#at_front" do
    it "should be true for an appeal with a form 9 date older than the latest docket month" do
      expect(first_tracer.at_front).to be_truthy
    end

    it "should be true for an appeal with a form 9 date equal to the latest docket month" do
      expect(second_tracer.at_front).to be_truthy
    end

    it "should be false for an appeal with a form 9 date newer than the latest docket month" do
      expect(last_tracer.at_front).to be_falsey
    end
  end

  context "#to_hash" do
    subject { second_tracer.to_hash }

    it "includes the expected attributes" do
      expect(subject[:front]).to eq(true)
      expect(subject[:total]).to eq(123_456)
      expect(subject[:ahead]).to eq(13_456)
      expect(subject[:ready]).to eq(8456)
      expect(subject[:month]).to eq(11.months.ago.to_date.beginning_of_month)
      expect(subject[:docketMonth]).to eq(11.months.ago.to_date.beginning_of_month)
      expect(subject[:eta]).to eq(nil)
    end
  end
end
