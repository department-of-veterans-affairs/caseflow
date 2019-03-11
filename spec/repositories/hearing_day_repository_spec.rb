# frozen_string_literal: true

describe HearingDayRepository do
  context ".fetch_hearing_day_slots" do
    subject { HearingDayRepository.fetch_hearing_day_slots(regional_office) }

    context "returns slots for Winston-Salem" do
      let(:regional_office) { "RO18" }

      it { is_expected.to eq 12 }
    end

    context "returns slots for Denver" do
      let(:regional_office) { "RO37" }

      it { is_expected.to eq 10 }
    end

    context "returns slots for Los_Angeles" do
      let(:regional_office) { "RO44" }

      it { is_expected.to eq 8 }
    end
  end

  context ".find_hearing_day" do
    let!(:hearing_day) { create(:travel_board_schedule) }

    it "finds VACOLS travel board hearing days" do
      expect(HearingDay.find_hearing_day("T",
                                         [hearing_day[:tbyear],
                                          hearing_day[:tbtrip].to_s,
                                          hearing_day[:tbleg].to_s].join("-"))[:tbstdate]).to eq(hearing_day[:tbstdate])
    end
  end
end
