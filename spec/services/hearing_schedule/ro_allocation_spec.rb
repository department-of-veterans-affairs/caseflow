describe HearingSchedule::RoAllocation do
  let(:ro_allocation) { Class.new { include HearingSchedule::RoAllocation } }

  context ".sort_monthly_order" do

    subject { ro_allocation.sort_monthly_order(months) }

    context "sequential six months" do
      let(:months) { [[4, 2018], [5, 2018], [6, 2018], [7, 2018], [8, 2018], [9, 2018]] }
      it { expect(subject).to eq [[4, 2018], [9, 2018], [5, 2018], [8, 2018], [6, 2018], [7, 2018]] }
    end

    context "three months" do
      let(:months) { [[1, 2018], [2, 2018], [3, 2018]] }
      it { expect(subject).to eq [[1, 2018], [3, 2018], [2, 2018]] }
    end

    context "odd number months" do
      let(:months) { [[10, 2018], [5, 2018], [2, 2018], [11, 2018], [1, 2018]] }
      it { expect(subject).to eq [[10, 2018], [1, 2018], [5, 2018], [11, 2018], [2, 2018]] }
    end
  end

  context ".validate_available_days" do
    let(:allocated_days) { {[4, 2018]=>10, [9, 2018]=>21, [5, 2018]=>21, [8, 2018]=>22, [6, 2018]=>22, [7, 2018]=>21} }
    let(:available_days) { {[4, 2018]=>12, [5, 2018]=>20, [6, 2018]=>19, [7, 2018]=>17, [8, 2018]=>20, [9, 2018]=>16} }
    let(:num_of_rooms) { 1 }
    subject { ro_allocation.validate_available_days(allocated_days, available_days, num_of_rooms) }

    context "raise exception due to not enough available days" do
      let(:available_days) { {[4, 2018]=>15, [5, 2018]=>21, [6, 2018]=>19, [7, 2018]=>17, [8, 2018]=>20, [9, 2018]=>16} }
      it { expect{ subject }.to raise_error(HearingSchedule::RoAllocation::NotEnoughAvailableDays) }
    end

    context "move allocated days" do
      let(:allocated_days) { {[4, 2018]=>14, [9, 2018]=>12, [5, 2018]=>20, [8, 2018]=>20, [6, 2018]=>19, [7, 2018]=>17} }
      it { expect(subject).to eq({[4, 2018]=>12, [9, 2018]=>14, [5, 2018]=>20, [8, 2018]=>20, [6, 2018]=>19, [7, 2018]=>17}) }
    end

    context "odd days" do
      let(:allocated_days) { {[1, 2018]=>13, [2, 2018]=>11} }
      let(:available_days) { {[1, 2018]=>15, [2, 2018]=>9} }

      it { expect(subject).to eq({[1, 2018]=>15, [2, 2018]=>9 }) }
    end

    context "multiple number of rooms" do
      let(:allocated_days) { {[1, 2018]=>20, [2, 2018]=>30, [6, 2018]=>20} }
      let(:available_days) { {[1, 2018]=>10, [2, 2018]=>15, [6, 2018]=>12} }
      let(:num_of_rooms) { 2 }

      it { expect(subject).to eq({[1, 2018]=>20, [2, 2018]=>30, [6, 2018]=>20 }) }
    end
  end

  context ".distribute_days_evenly" do
    let(:allocated_days) { {[4, 2018]=>11, [9, 2018]=>21, [5, 2018]=>22, [8, 2018]=>23, [6, 2018]=>21, [7, 2018]=>20} }
    let(:available_days) { {[4, 2018]=>9, [5, 2018]=>19, [6, 2018]=>19, [7, 2018]=>17, [8, 2018]=>21, [9, 2018]=>17} }
    let(:num_of_rooms) { 2 }
    subject { ro_allocation.distribute_days_evenly(allocated_days, available_days, num_of_rooms) }

    context "for two rooms" do
      it { expect(subject).to eq({[4, 2018]=>12, [9, 2018]=>20, [5, 2018]=>22, [8, 2018]=>24, [6, 2018]=>20, [7, 2018]=>20})}
      it { expect(subject.values.inject(:+)).to eq(118) }
    end

    context "for miltiple three rooms" do
      let(:num_of_rooms) { 3 }

      it { expect(subject).to eq({[4, 2018]=>12, [9, 2018]=>21, [5, 2018]=>24, [8, 2018]=>21, [6, 2018]=>21, [7, 2018]=>19}) }
      it { expect(subject.values.inject(:+)).to eq(118) }
    end

    context "for miltiple three rooms" do
      let(:allocated_days) { {[4, 2018]=>0, [9, 2018]=>1, [5, 2018]=>1, [8, 2018]=>0, [6, 2018]=>1, [7, 2018]=>0} }
      let(:available_days) { {[4, 2018]=>9, [5, 2018]=>19, [6, 2018]=>19, [7, 2018]=>17, [8, 2018]=>21, [9, 2018]=>17} }
      let(:num_of_rooms) { 1 }

      it { expect(subject).to eq({[4, 2018]=>0, [9, 2018]=>1, [5, 2018]=>1, [8, 2018]=>0, [6, 2018]=>1, [7, 2018]=>0}) }
      it { expect(subject.values.inject(:+)).to eq(3) }
    end
  end
end