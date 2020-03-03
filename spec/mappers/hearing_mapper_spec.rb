# frozen_string_literal: true

describe HearingMapper do
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
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:central] }

      it { is_expected.to eq "1" }
    end

    context "when disposition is held and it is video hearing" do
      let(:hearing_disp) { "H" }
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:video] }

      it { is_expected.to eq "6" }
    end

    context "when disposition is held and it is travel board hearing" do
      let(:hearing_disp) { "H" }
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:travel] }

      it { is_expected.to eq "2" }
    end

    context "when disposition is postponed" do
      let(:hearing_disp) { "P" }
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:travel] }

      it { is_expected.to eq nil }
    end

    context "when disposition is cancelled" do
      let(:hearing_disp) { "C" }
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:video] }

      it { is_expected.to eq "5" }
    end

    context "when disposition is not held" do
      let(:hearing_disp) { "N" }
      let(:hearing_type) { HearingDay::REQUEST_TYPES[:central] }

      it { is_expected.to eq "5" }
    end
  end

  context ".datetime_based_on_type" do
    before { Time.zone = "America/Chicago" }
    subject do
      HearingMapper.datetime_based_on_type(datetime: datetime,
                                           regional_office_key: regional_office_key,
                                           type: type)
    end
    # Manila regional office, timezone "Asia/Manila"
    let(:regional_office_key) { "RO58" }
    let(:datetime) { Time.new(2013, 9, 5, 20, 0, 0, "-08:00") }

    context "when travel board" do
      let(:type) { HearingDay::REQUEST_TYPES[:travel] }

      it "uses a regional office timezone to set the zone" do
        expect(subject.day).to eq 5
        expect(subject.hour).to eq 16
        expect(subject.zone).to eq "EDT"
      end
    end

    context "when video" do
      let(:type) { HearingDay::REQUEST_TYPES[:video] }

      it "uses a regional office timezone to set the zone" do
        expect(subject.day).to eq 5
        expect(subject.hour).to eq 16
        expect(subject.zone).to eq "EDT"
      end
    end

    context "when central_office" do
      let(:type) { HearingDay::REQUEST_TYPES[:central] }

      it "does not use a regional office timezone" do
        expect(subject.day).to eq 6
        expect(subject.hour).to eq 4
        expect(subject.zone).to eq "CDT"
      end
    end
  end

  context ".hearing_fields_to_vacols_codes" do
    subject { HearingMapper.hearing_fields_to_vacols_codes(info) }

    context "when all values are present" do
      let(:info) do
        { notes: "test notes",
          aod: "none",
          transcript_requested: false,
          disposition: "postponed",
          hold_open: 60,
          add_on: false,
          representative_name: "test name" }
      end

      it "should convert to Vacols values" do
        result = subject
        expect(result[:notes]).to eq "test notes"
        expect(result[:aod]).to eq :N
        expect(result[:transcript_requested]).to eq :N
        expect(result[:disposition]).to eq :P
        expect(result[:hold_open]).to eq 60
        expect(result[:add_on]).to eq :N
        expect(result[:representative_name]).to eq "test name"
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
          aod: :filed,
          representative_name: nil }
      end

      it "should clear these values" do
        result = subject
        expect(result.values.size).to eq 3
        expect(result[:notes]).to eq nil
        expect(result[:aod]).to eq :Y
        expect(result[:representative_name]).to eq nil
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

    context "when notes is not valid" do
      let(:info) do
        { notes: 77 }
      end
      it "raises InvalidNotesError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidNotesError)
      end
    end

    context "when representative name is not valid" do
      let(:info) do
        { representative_name: 77 }
      end
      it "raises InvalidNotesError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidRepresentativeNameError)
      end
    end

    context "when addon is not valid" do
      let(:info) do
        { add_on: :foo }
      end
      it "raises InvalidNotesError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidAddOnError)
      end
    end

    context "when aod is false" do
      let(:info) do
        { aod: false }
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

    context "when disposition is nil" do
      let(:info) do
        { disposition: nil }
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

    context "when hold_open is false" do
      let(:info) do
        { hold_open: false }
      end
      it "raises InvalidHoldOpenError error" do
        expect { subject }.to raise_error(HearingMapper::InvalidHoldOpenError)
      end
    end
  end
end
