describe DocketSnapshot do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  let(:snapshot) { DocketSnapshot.create }
  let(:another_snapshot) { DocketSnapshot.create }

  context ".create" do
    subject { snapshot }

    it "creates a new snapshot and tracers" do
      expect(subject.docket_count).to eq(123456)
      expect(subject.latest_docket_month).to eq(Date.new(2014, 2, 1))
      expect(subject.docket_tracers.count).to eq(13)
      expect(subject.docket_tracers.first.month).to eq(Date.new(2014, 1, 1))
      expect(subject.docket_tracers.first.ahead_count).to eq(3456)
      expect(subject.docket_tracers.first.ahead_and_ready_count).to eq(3456)
      expect(subject.docket_tracers.last.month).to eq(Date.new(2015, 1, 1))
      expect(subject.docket_tracers.last.ahead_count).to eq(123456)
      expect(subject.docket_tracers.last.ahead_and_ready_count).to eq(63456)
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
end
