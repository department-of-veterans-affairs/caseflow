# frozen_string_literal: true

describe HearingRepository, :all_dbs do
  let(:regional_office) { "RO42" }
  let(:hearing_date) { Time.zone.now }
  let(:ama_disposition) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      regional_office: regional_office,
      scheduled_for: hearing_date,
      request_type: HearingDay::REQUEST_TYPES[:video]
    )
  end
  let(:hearing) do
    create(:hearing, regional_office: regional_office, hearing_day: hearing_day, disposition: ama_disposition)
  end

  before do
    Timecop.freeze(Time.utc(2017, 10, 4))
    Time.zone = "America/Chicago"
  end

  context ".fetch_hearings_for_parent" do
    let(:hearing_date) { Time.utc(2019, 5, 2) }
    let(:case_hearing) { create(:case_hearing, hearing_date: hearing_date) }

    subject { HearingRepository.fetch_hearings_for_parents(case_hearing.vdkey) }

    it "should have one record" do
      expect(subject[case_hearing.vdkey].size).to eq(1)
    end

    it "should be the expected row" do
      expect(subject[case_hearing.vdkey][0].vacols_id).to eq(case_hearing.id.to_s)
    end

    context "for case with nil folder number" do
      let(:case_hearing) { create(:case_hearing, hearing_date: hearing_date, folder_nr: nil) }

      it "should be empty" do
        expect(subject).to eq({})
      end

      # https://github.com/department-of-veterans-affairs/caseflow/issues/12321
      it "should not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end

  context ".slot_new_hearing" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    let(:staff_record) { create(:staff) }
    let(:hearing_day) { create(:hearing_day, scheduled_for: Date.new(2019, 3, 2)) }

    before do
      RequestStore.store[:current_user] = create(:user, vacols_uniq_id: staff_record.slogid)
    end

    it "slots hearing at correct time" do
      HearingRepository.slot_new_hearing(
        hearing_day_id: hearing_day.id,
        scheduled_time_string: "09:00",
        appeal: legacy_appeal
      )

      expect(VACOLS::CaseHearing.find_by(vdkey: hearing_day.id)
        .hearing_date.to_datetime.in_time_zone("UTC").hour).to eq(9)
    end

    context "for a full hearing day" do
      before do
        Timecop.return
      end

      let!(:hearings) do
        (1...hearing_day.total_slots + 1).map do |idx|
          create(
            :hearing,
            appeal: create(:appeal, receipt_date: Date.new(2019, 5, idx)),
            hearing_day: hearing_day
          )
        end
      end

      it "throws a hearing day full error" do
        expect do
          HearingRepository.slot_new_hearing(
            hearing_day_id: hearing_day.id,
            scheduled_time_string: "9:30",
            appeal: legacy_appeal
          )
        end.to raise_error(HearingRepository::HearingDayFull)
      end

      it "does not throw an error if the override flag is set" do
        expect do
          HearingRepository.slot_new_hearing(
            {
              hearing_day_id: hearing_day.id,
              scheduled_time_string: "9:30",
              appeal: legacy_appeal
            },
            override_full_hearing_day_validation: true
          )
        end.not_to raise_error
      end
    end
  end

  context ".set_vacols_values" do
    let(:date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:hearing) { create(:legacy_hearing) }
    let(:hearing_day) { HearingDay.first }
    let(:notes) { "test notes" }
    let(:representative_name) { "test representative name" }
    let(:hearing_hash) do
      OpenStruct.new(
        hearing_date: date,
        hearing_type: HearingDay::REQUEST_TYPES[:video],
        hearing_pkseq: "12345678",
        hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:no_show],
        aod: "Y",
        tranreq: nil,
        holddays: 90,
        notes1: notes,
        repname: representative_name,
        bfso: "E",
        bfregoff: "RO36",
        vdkey: hearing_day.id
      )
    end

    subject { HearingRepository.set_vacols_values(hearing, hearing_hash) }

    it "assigns values properly" do
      expect(subject.request_type).to eq(HearingDay::REQUEST_TYPES[:video])
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.scheduled_for.class).to eq(ActiveSupport::TimeWithZone)
      expect(subject.disposition).to eq(Constants.HEARING_DISPOSITION_TYPES.no_show)
      expect(subject.aod).to eq :filed
      expect(subject.transcript_requested).to eq nil
      expect(subject.hold_open).to eq 90
      expect(subject.notes).to eq notes
      expect(subject.representative_name).to eq representative_name
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

  context ".maybe_ready_for_reminder_email" do
    let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: hearing) }

    subject { described_class.maybe_ready_for_reminder_email }

    shared_examples "include or exclude hearings depending on the number of days out from the hearing" do
      context "within 7 days" do
        let(:hearing_date) { Time.zone.now + 7.days }

        it "returns the virtual hearing" do
          expect(subject).to eq([virtual_hearing])
        end
      end

      context "is in 10 days" do
        let(:hearing_date) { Time.zone.now + 10.days }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end
    end

    context "for an AMA hearing" do
      context "active virtual hearing" do
        include_examples "include or exclude hearings depending on the number of days out from the hearing"
      end

      %w[postponed cancelled no_show held].each do |disposition|
        context "#{disposition} virtual hearing" do
          let(:ama_disposition) { disposition }

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context "for a Legacy hearing" do
      let(:legacy_dispositon) { nil }
      let(:hearing) do
        create(
          :legacy_hearing,
          regional_office: regional_office,
          hearing_day_id: hearing_day.id,
          case_hearing: create(:case_hearing, hearing_disp: legacy_dispositon)
        )
      end

      context "active virtual hearing" do
        include_examples "include or exclude hearings depending on the number of days out from the hearing"
      end

      %w[P C N H].each do |disposition_code|
        context "#{VACOLS::CaseHearing::HEARING_DISPOSITIONS[disposition_code.to_sym]} virtual hearing" do
          let(:ama_disposition) { disposition_code }

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end
  end
end
