describe HearingRepository do
  before do
    Timecop.freeze(Time.utc(2017, 10, 4))
    Time.zone = "America/Chicago"
  end

  context ".slot_new_hearing" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    let(:time) do
      {
        "h" => "9",
        "m" => "00",
        "offset" => "-500"
      }
    end
    let(:staff_record) { create(:staff) }

    before do
      RequestStore.store[:current_user] = OpenStruct.new(vacols_uniq_id: staff_record.slogid)

      HearingDay.create_hearing_day(
        hearing_type: "C",
        hearing_date: 1.day.from_now.to_s,
        room_info: "123",
        judge_id: "456",
        regional_office: "RO18"
      )
    end

    it "slots hearing at correct time" do
      HearingRepository.slot_new_hearing(VACOLS::CaseHearing.first.hearing_pkseq, time, legacy_appeal)
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
      expect(subject.regional_office_key).to eq "SO62"
    end
  end

  context ".hearings_for" do
    subject { HearingRepository.hearings_for(records) }

    let!(:case_hearing) { create(:case_hearing) }

    let(:record1) do
      OpenStruct.new(
        hearing_type: "T",
        master_record_type: nil,
        bfregoff: "RO36",
        hearing_pkseq: case_hearing.hearing_pkseq,
        folder_nr: "5678",
        hearing_date: Time.zone.now
      )
    end

    let(:record2) do
      OpenStruct.new(
        folder_nr: "VIDEO RO15",
        hearing_date: Time.zone.now,
        master_record_type: :video
      )
    end

    let(:record3) do
      OpenStruct.new(
        tbro: "RO19",
        tbstdate: Time.zone.now,
        tbenddate: Time.zone.now,
        master_record_type: :travel_board
      )
    end

    let(:records) { [record1, record2, record3] }

    it "should create hearing records" do
      expect(subject.size).to eq 3
      expect(subject.first.vacols_id).to eq case_hearing.hearing_pkseq.to_s
      expect(subject.first.master_record).to eq false
      expect(subject.second.master_record).to eq true
      expect(subject.third.master_record).to eq true
    end
  end
end
