describe HearingMapper do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".bfha_vacols_code" do
    let(:hearing) do
      OpenStruct.new(
        folder_nr: "123C",
        hearing_disp: hearing_disp,
        hearing_type: hearing_type
      )
    end

    subject { HearingMapper.bfha_vacols_code(hearing) }

    context "when disposition is held and it is central office hearing" do
      let(:hearing_disp) { "H" }
      let(:hearing_type) { "C" }

      it { is_expected.to eq "1" }
    end

    context "when disposition is held and it is video hearing" do
      let(:hearing_disp) { "H" }
      let(:hearing_type) { "V" }

      it { is_expected.to eq "6" }
    end

    context "when disposition is held and it is travel board hearing" do
      let(:hearing_disp) { "H" }
      let(:hearing_type) { "T" }

      it { is_expected.to eq "2" }
    end

    context "when disposition is postponed" do
      let(:hearing_disp) { "P" }
      let(:hearing_type) { "T" }


      it { is_expected.to eq nil }
    end

    context "when disposition is cancelled" do
      let(:hearing_disp) { "C" }
      let(:hearing_type) { "V" }


      it { is_expected.to eq "5" }
    end

    context "when disposition is not held" do
      let(:hearing_disp) { "N" }
      let(:hearing_type) { "C" }

      it { is_expected.to eq "5" }
    end
  end

  context ".hearing_fields_to_vacols_codes" do
    subject { HearingMapper.hearing_fields_to_vacols_codes(info) }

    context "when all values are present" do
      let(:info) do
        { notes: "test notes",
          aod: :none,
          transcript_requested: false,
          disposition: :postponed,
          hold_open: 60 }
      end

      it "should convert to Vacols values" do
        result = subject
        expect(result[:notes]).to eq "test notes"
        expect(result[:aod]).to eq :N
        expect(result[:transcript_requested]).to eq :N
        expect(result[:disposition]).to eq :P
        expect(result[:hold_open]).to eq 60
      end
    end

    context "when some values are missing" do
      let(:info) do
        { notes: "test notes",
          aod: :granted }
      end

      it "should skip these values" do
        result = subject
        expect(result.values.size).to eq 2
        expect(result[:notes]).to eq "test notes"
        expect(result[:aod]).to eq :G
      end
    end

    context "values with nil" do
      let(:info) do
        { notes: nil,
          aod: :filed }
      end

      it "should clear these values" do
        result = subject
        expect(result.values.size).to eq 2
        expect(result[:notes]).to eq nil
        expect(result[:aod]).to eq :Y
      end
    end

    context "when some values do not need Vacols update" do
      let(:info) do
        { worksheet_military_service: "Vietnam 1968 - 1970" }
      end

      it "should skip these values" do
        result = subject
        expect(result.values.size).to eq 0
      end
    end

    context "when aod is not valid" do
      let(:info) do
        { aod: :foo }
      end
      it "raises InvalidAodError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidAodError)
      end
    end

    context "when disposition is not valid" do
      let(:info) do
        { disposition: :foo }
      end
      it "raises InvalidDispositionError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidDispositionError)
      end
    end

    context "when transcript_requested is not valid" do
      let(:info) do
        { transcript_requested: :foo }
      end
      it "raises InvalidTranscriptRequestedError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidTranscriptRequestedError)
      end
    end

    context "when hold_open is not valid" do
      let(:info) do
        { hold_open: -7 }
      end
      it "raises InvalidHoldOpenError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidHoldOpenError)
      end
    end
  end
end
