describe HearingDayRepository do
  context ".fetch_hearing_day_slots", skip: "Flakey test" do
    subject { HearingDayRepository.fetch_hearing_day_slots(regional_office: "Winston-Salem") }
    let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing_day) do
      create(
        :case_hearing,
        folder_nr: "VIDEO RO18",
        hearing_date: Date.new(2018, 9, 20),
        hearing_type: HearingDay::REQUEST_TYPES[:video]
      )
    end
    it {
      is_expected.to eq(10)
    }
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
