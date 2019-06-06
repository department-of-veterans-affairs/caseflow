# frozen_string_literal: true

describe HearingRepository do
  before do
    Timecop.freeze(Time.utc(2017, 10, 4))
    Time.zone = "America/Chicago"
  end

  context ".slot_new_hearing" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    let(:staff_record) { create(:staff) }
    let(:hearing_day) { create(:hearing_day, scheduled_for: Date.new(2019, 3, 2)) }

    before do
      RequestStore.store[:current_user] = OpenStruct.new(vacols_uniq_id: staff_record.slogid)
    end

    it "slots hearing at correct time" do
      HearingRepository.slot_new_hearing(hearing_day.id, scheduled_time_string: "09:00", appeal: legacy_appeal)

      expect(VACOLS::CaseHearing.find_by(vdkey: hearing_day.id)
        .hearing_date.to_datetime.in_time_zone("UTC").hour).to eq(9)
    end
  end

  context ".set_vacols_values" do
    subject { HearingRepository.set_vacols_values(hearing, hearing_hash) }
    let(:date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:hearing) { create(:legacy_hearing) }
    let(:hearing_day) { HearingDay.first }

    let(:hearing_hash) do
      OpenStruct.new(
        hearing_date: date,
        hearing_type: HearingDay::REQUEST_TYPES[:video],
        hearing_pkseq: "12345678",
        hearing_disp: "N",
        aod: "Y",
        tranreq: nil,
        holddays: 90,
        notes1: "test notes",
        repname: "test rep name",
        bfso: "E",
        bfregoff: "RO36",
        vdkey: hearing_day.id
      )
    end

    it "assigns values properly" do
      expect(subject.request_type).to eq(HearingDay::REQUEST_TYPES[:video])
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.scheduled_for.class).to eq(ActiveSupport::TimeWithZone)
      expect(subject.disposition).to eq(Constants.HEARING_DISPOSITION_TYPES.no_show)
      expect(subject.aod).to eq :filed
      expect(subject.transcript_requested).to eq nil
      expect(subject.hold_open).to eq 90
      expect(subject.notes).to eq "test notes"
      expect(subject.representative_name).to eq "test rep name"
      expect(subject.representative).to eq "Jewish War Veterans"
    end
  end

  context ".hearings_for" do
    subject { HearingRepository.hearings_for(records) }

    let!(:case_hearing) { create(:case_hearing) }

    let(:record1) do
      OpenStruct.new(
        hearing_type: HearingDay::REQUEST_TYPES[:travel],
        bfregoff: "RO36",
        hearing_pkseq: case_hearing.hearing_pkseq,
        folder_nr: "5678",
        hearing_date: Time.zone.now
      )
    end

    let(:records) { [record1] }

    it "should create hearing records" do
      expect(subject.size).to eq 1
      expect(subject.first.vacols_id).to eq case_hearing.hearing_pkseq.to_s
    end
  end
end
