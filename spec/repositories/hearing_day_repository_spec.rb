describe HearingDayRepository do
  context ".slots_based_on_type" do
    subject { HearingDayRepository.slots_based_on_type(staff: staff, type: type, date: date) }
    let(:staff) { create(:staff, stc2: 2, stc3: 3, stc4: 4) }

    context "returns 1 for central office hearings" do
      let(:type) { HearingDay::HEARING_TYPES[:central] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 11 }
    end

    context "returns stc4 for video hearings" do
      let(:type) { HearingDay::HEARING_TYPES[:video] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 4 }
    end

    context "returns stc2 for travel board hearings on friday" do
      let(:type) { HearingDay::HEARING_TYPES[:travel] }
      let(:date) { Date.new(2018, 9, 21) }
      it { is_expected.to eq 2 }
    end

    context "returns stc3 for travel board hearings on thursday" do
      let(:type) { HearingDay::HEARING_TYPES[:travel] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 3 }
    end
  end

  context ".fetch_hearing_day_slots" do
    subject { HearingDayRepository.fetch_hearing_day_slots(staff, hearing_day) }
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing_day) do
      { regional_office: "RO04",
        hearing_date: Date.new(2018, 9, 20),
        hearing_type: HearingDay::HEARING_TYPES[:video] }
    end
    it {
      is_expected.to eq(4)
    }
  end
end
