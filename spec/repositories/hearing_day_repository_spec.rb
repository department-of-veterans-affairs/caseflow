describe HearingDayRepository do
  context ".slots_based_on_type" do
    subject { HearingDayRepository.slots_based_on_type(staff: staff, type: type, date: date) }
    let(:staff) { create(:staff, stc2: 2, stc3: 3, stc4: 4) }

    context "returns 1 for central office hearings" do
      let(:type) { HearingDay::REQUEST_TYPES[:central] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 11 }
    end

    context "returns stc4 for video hearings" do
      let(:type) { HearingDay::REQUEST_TYPES[:video] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 4 }
    end

    context "returns stc2 for travel board hearings on friday" do
      let(:type) { HearingDay::REQUEST_TYPES[:travel] }
      let(:date) { Date.new(2018, 9, 21) }
      it { is_expected.to eq 2 }
    end

    context "returns stc3 for travel board hearings on thursday" do
      let(:type) { HearingDay::REQUEST_TYPES[:travel] }
      let(:date) { Date.new(2018, 9, 20) }
      it { is_expected.to eq 3 }
    end
  end

  context ".fetch_hearing_day_slots" do
    let!(:hearing_day) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             regional_office: "RO18",
             scheduled_for: Date.new(2019, 4, 15))
    end
    it "Total time slots" do
      HearingDayRepository.fetch_hearing_day_slots(regional_office: "Winston-Salem")
      expect (HearingDocket::SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office: "Winston-Salem")]).to eq(9)
    end
  end

  context ".ro staff hash" do
    subject { HearingDayRepository.ro_staff_hash(%w[RO13 RO18]) }
    let!(:staff_rows) do
      create(:staff, stafkey: "RO13", stc2: 2, stc3: 3, stc4: 4)
      create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4)
    end

    it {
      expect(subject.size).to eq(2)
    }
  end
end
