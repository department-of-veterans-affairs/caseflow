describe HearingRepository do
  before do
    Timecop.freeze(Time.utc(2017, 10, 4))
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
        repname: "test rep name",
        bfso: "E",
        bfregoff: "RO36"
      )
    end

    it "assigns values properly" do
      expect(subject.venue[:city]).to eq("San Antonio")
      expect(subject.type).to eq(:video)
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.date.class).to eq(ActiveSupport::TimeWithZone)
      expect(subject.disposition).to eq(:no_show)
      expect(subject.aod).to eq :filed
      expect(subject.transcript_requested).to eq nil
      expect(subject.hold_open).to eq 90
      expect(subject.notes).to eq "test notes"
      expect(subject.representative_name).to eq "test rep name"
      expect(subject.representative).to eq "Jewish War Veterans"
    end
  end

  context ".slots_based_on_type" do
    subject { HearingRepository.slots_based_on_type(staff: staff, type: type, date: date) }

    context "when it is a central office" do
      let(:staff) { OpenStruct.new }
      let(:type) { :central_office }
      let(:date) { Time.zone.now }
      it { is_expected.to eq 11 }
    end

    context "when it is a video, use staff.stc4" do
      let(:staff) { OpenStruct.new(stc2: 8, stc3: 9, stc4: 12) }
      let(:type) { :video }
      let(:date) { Time.zone.now }
      it { is_expected.to eq 12 }
    end

    context "when it is a travel board" do
      let(:staff) { OpenStruct.new(stc2: 8, stc3: 9, stc4: 12) }
      let(:type) { :travel }

      context "when it is a Monday, use staff.stc2" do
        let(:date) { 1.day.ago }
        it { is_expected.to eq 8 }
      end

      context "when it is a Tuesday, use staff.stc3" do
        let(:date) { Time.zone.now }
        it { is_expected.to eq 9 }
      end
    end
  end

  context ".hearing_datetime" do
    subject { HearingRepository.hearing_datetime(Time.zone.now, regional_office_key) }

    context "uses regional office timezone to set the zone" do
      let(:regional_office_key) { "RO58" }

      it "calculates the date and hour correctly" do
        expect(subject.day).to eq 3
        expect(subject.hour).to eq 7
        expect(subject.zone).to eq "EDT"
      end
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
      it { is_expected.to eq(type: :video, regional_office_key: "RO15", date: nil) }
    end

    context "when a hearing is not a master record" do
      let(:vacols_record) do
        OpenStruct.new(
          hearing_type: "T",
          master_record_type: nil,
          bfregoff: "RO36"
        )
      end
      it { is_expected.to eq(type: :travel, regional_office_key: "RO36", date: nil) }
    end
  end
end
