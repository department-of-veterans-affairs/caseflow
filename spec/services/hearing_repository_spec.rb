describe HearingRepository do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".transform_hearing_info" do
    subject { HearingRepository.transform_hearing_info(info) }

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
  end

  context ".set_vacols_values" do
    subject { HearingRepository.set_vacols_values(hearing, hearing_hash) }
    let(:date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:hearing) { Generators::Hearing.create }

    let(:hearing_hash) do
      OpenStruct.new(
        hearing_venue: "SO62",
        hearing_date: date,
        hearing_type: "V",
        hearing_pkseq: "12345678",
        hearing_disp: "N",
        aod: "Y",
        tranreq: nil,
        holddays: 90,
        notes1: "test notes"
      )
    end

    it "assigns values properly" do
      expect(subject.venue[:city]).to eq("San Antonio")
      expect(subject.type).to eq(:video)
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.date).to eq(date)
      expect(subject.disposition).to eq(:no_show)
      expect(subject.aod).to eq :filed
      expect(subject.transcript_requested).to eq nil
      expect(subject.hold_open).to eq 90
      expect(subject.notes).to eq "test notes"
    end
  end
end
