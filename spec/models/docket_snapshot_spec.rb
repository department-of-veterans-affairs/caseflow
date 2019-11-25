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
  let(:another_snapshot) { DocketSnapshot.create }

  context ".create" do
    subject { snapshot }

    it "creates a new snapshot and tracers" do
      expect(subject.docket_count).to eq(123_456)
      expect(subject.latest_docket_month).to eq(Date.new(2014, 2, 1))
      expect(subject.docket_tracers.count).to eq(13)
      expect(subject.docket_tracers.first.month).to eq(Date.new(2014, 1, 1))
      expect(subject.docket_tracers.first.ahead_count).to eq(3456)
      expect(subject.docket_tracers.first.ahead_and_ready_count).to eq(3456)
      expect(subject.docket_tracers.last.month).to eq(Date.new(2015, 1, 1))
      expect(subject.docket_tracers.last.ahead_count).to eq(123_456)
      expect(subject.docket_tracers.last.ahead_and_ready_count).to eq(63_456)
    end

    context "when it is monday" do
      before do
        snapshot
        Timecop.freeze(Time.utc(2015, 2, 2, 12, 0, 0))
      end

      it "should reuse the latest_docket_month from last friday" do
        expect(another_snapshot.latest_docket_month).to eq(Date.new(2014, 2, 1))
      end
    end

    context "when it is next friday" do
      before do
        snapshot
        Timecop.freeze(Time.utc(2015, 2, 6, 12, 0, 0))
      end

      it "should update the latest_docket_month" do
        expect(another_snapshot.latest_docket_month).to eq(Date.new(2014, 3, 1))
      end
    end
  end

  context ".latest" do
    before do
      snapshot
      Timecop.freeze(Time.utc(2015, 2, 6, 12, 0, 0))
      another_snapshot
    end

    subject { DocketSnapshot.latest }

    it "should return the latest snapshot" do
      expect(subject).to eq(another_snapshot)
    end
  end

  context "#docket_tracer_for_form9_date" do
    before do
      allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
    end

    let(:date) { Date.new(2014, 2, 15) }
    subject { snapshot.docket_tracer_for_form9_date(date) }

    it "should return the tracer for the start of the month" do
      expect(subject.month).to eq(Date.new(2014, 2, 1))
    end
  end
end
