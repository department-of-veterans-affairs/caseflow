describe HearingRepository do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
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
        notes1: "test notes",
        repname: "test rep name"
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
      expect(subject.representative_name).to eq "test rep name"
    end
  end

  context ".slots_based_on_type" do
    subject { HearingRepository.slots_based_on_type(staff: staff, type: type, date: date) }

    context "when it is a central office" do
      let(:staff) { OpenStruct.new }
      let(:type) { :central_office }
      let(:date) { Time.now }
      it { is_expected.to eq 11 }
    end
  end

  context ".values_based_on_type" do
    subject { HearingRepository.values_based_on_type(vacols_record) }

    context "when a hearing is a video master record" do
      let(:vacols_record) do
        OpenStruct.new(
          hearing_type: "V",
          folder_nr: "VIDEO RO15",
          master_record_type: :video
        )
      end
      it { is_expected.to eq(type: :video, regional_office_key: "RO15") }
    end

    context "when a hearing is not a master record" do
      let(:vacols_record) do
        OpenStruct.new(
          hearing_type: "T",
          master_record_type: nil,
          brieff: OpenStruct.new(bfregoff: "RO36")
        )
      end
      it { is_expected.to eq(type: :travel, regional_office_key: "RO36") }
    end
  end
end
