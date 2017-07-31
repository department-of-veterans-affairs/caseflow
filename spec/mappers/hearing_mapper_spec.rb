describe HearingMapper do
  context ".bfha_vacols_code" do
    let(:hearing) do
      OpenStruct.new(
        folder_nr: "123C",
        hearing_disp: hearing_disp,
      )
    end

    let(:brieff) do
      OpenStruct.new(bfhr: bfhr, bfdocind: bfdocind)
    end

    subject { HearingMapper.bfha_vacols_code(hearing, brieff) }

    context "when disposition is held and it is central office hearing" do
      let(:hearing_disp) { "H" }
      let(:bfhr) { "1" }
      let(:bfdocind) { nil }

      it { is_expected.to eq "1" }
    end

    context "when disposition is held and it is video hearing" do
      let(:hearing_disp) { "H" }
      let(:bfhr) { "2" }
      let(:bfdocind) { "V" }

      it { is_expected.to eq "6" }
    end
  end
end