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
end
