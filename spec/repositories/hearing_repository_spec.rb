# frozen_string_literal: true

describe HearingRepository, :all_dbs do
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
    subject { described_class.maybe_ready_for_reminder_email }

    let(:regional_office) { "RO42" }
    let(:hearing_date) { Time.zone.now }
    let(:video_hearing_day) do
      create(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: hearing_date,
        request_type: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:central_hearing_day) do
      create(
        :hearing_day,
        regional_office: nil,
        scheduled_for: hearing_date,
        request_type: HearingDay::REQUEST_TYPES[:central]
      )
    end

    context "for both active ama and active legacy hearings" do
      let(:ama_disposition) { nil }
      let(:legacy_disposition) { nil }
      let!(:ama_virtual_hearing) do
        create(:hearing, regional_office: regional_office, hearing_day: video_hearing_day, disposition: ama_disposition)
      end
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: ama_virtual_hearing) }

      let!(:ama_video_hearing) do
        create(:hearing, regional_office: regional_office, hearing_day: video_hearing_day, disposition: ama_disposition)
      end
      let!(:ama_central_hearing) do
        create(
          :hearing,
          regional_office: regional_office,
          hearing_day: central_hearing_day,
          disposition: ama_disposition
        )
      end
      let!(:legacy_video_hearing) do
        create(
          :legacy_hearing,
          hearing_day: video_hearing_day,
          disposition: legacy_disposition
        )
      end

      context "is in 60 days" do
        let(:hearing_date) { Time.zone.now + 60.days }

        it "returns the hearings" do
          expect(subject.sort_by(&:id)).to eq(
            [ama_virtual_hearing, ama_video_hearing, ama_central_hearing, legacy_video_hearing].sort_by(&:id)
          )
        end
      end

      context "is in 7 days" do
        let(:hearing_date) { Time.zone.now + 7.days }

        it "returns the hearings" do
          expect(subject.sort_by(&:id)).to eq(
            [ama_virtual_hearing, ama_video_hearing, ama_central_hearing, legacy_video_hearing].sort_by(&:id)
          )
        end
      end

      context "is in 70 days" do
        let(:hearing_date) { Time.zone.now + 70.days }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end
    end

    context "for an AMA hearing" do
      %w[postponed cancelled scheduled_in_error].each do |disposition|
        context "#{disposition} virtual hearing" do
          let(:ama_disposition) { disposition }
          let(:hearing_date) { Time.zone.now + 7.days }
          let(:hearing) do
            create(:hearing, disposition: ama_disposition, hearing_day: video_hearing_day)
          end

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context "for a Legacy hearing" do
      %w[P C E].each do |disposition_code|
        context "#{VACOLS::CaseHearing::HEARING_DISPOSITIONS[disposition_code.to_sym]} virtual hearing" do
          let(:legacy_disposition) { disposition_code }
          let!(:hearing) do
            create(
              :legacy_hearing,
              regional_office: regional_office,
              hearing_day: central_hearing_day,
              case_hearing: create(:case_hearing, hearing_disp: legacy_disposition)
            )
          end
          let(:hearing_date) { Time.zone.now + 7.days }

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end
  end

  context ".maybe_needs_email_sent_status_checked" do
    subject { described_class.maybe_needs_email_sent_status_checked }
    let(:regional_office) { "RO42" }
    let(:hearing_date) { Time.zone.now }
    let(:video_hearing_day) do
      create(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: hearing_date,
        request_type: HearingDay::REQUEST_TYPES[:video]
      )
    end

    context "for both active ama and active legacy hearings" do
      let(:ama_disposition) { nil }
      let(:legacy_disposition) { nil }

      let(:ama_video_hearing) do
        create(
          :hearing,
          regional_office: regional_office,
          hearing_day: video_hearing_day,
          disposition: ama_disposition
        )
      end

      let(:legacy_video_hearing) do
        create(
          :legacy_hearing,
          regional_office: regional_office,
          hearing_day_id: video_hearing_day.id,
          case_hearing: create(:case_hearing, hearing_disp: legacy_disposition)
        )
      end

      let!(:ama_sent_event_appellant) do
        create(
          :sent_hearing_email_event,
          recipient_role: "appellant",
          hearing: ama_video_hearing
        )
      end
      let!(:ama_sent_event_representative) do
        create(
          :sent_hearing_email_event,
          recipient_role: "representative",
          hearing: ama_video_hearing
        )
      end

      let!(:legacy_sent_event_appellant) do
        create(
          :sent_hearing_email_event,
          recipient_role: "appellant",
          hearing: legacy_video_hearing
        )
      end

      let!(:legacy_sent_event_representative) do
        create(
          :sent_hearing_email_event,
          recipient_role: "representative",
          hearing: legacy_video_hearing
        )
      end

      context "hearings are in the past" do
        let(:hearing_date) { Time.zone.now - 10.days }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end

      context "hearings are in the future" do
        let(:hearing_date) { Time.zone.now + 7.days }

        context "when send_successful is not nil" do
          let(:send_successful) { true }
          let!(:sent_event_with_sent_status) do
            create(:sent_hearing_email_event, send_successful: send_successful, hearing: ama_video_hearing)
          end

          it "does not return event" do
            expect(subject.length).to eq(4)
            expect(subject.pluck(:id)).not_to include(sent_event_with_sent_status.id)
          end
        end

        context "when recipient is not appellant or representative" do
          let(:recipient_role) { "judge" }
          let!(:sent_event_judge) do
            create(:sent_hearing_email_event, recipient_role: recipient_role, hearing: ama_video_hearing)
          end

          it "does not return event" do
            expect(subject.length).to eq(4)
            expect(subject.pluck(:id)).not_to include(sent_event_judge.id)
          end
        end

        it "returns the hearings" do
          expect(subject.sort_by(&:id)).to eq(
            [
              ama_sent_event_appellant,
              ama_sent_event_representative,
              legacy_sent_event_appellant,
              legacy_sent_event_representative
            ].sort_by(&:id)
          )
        end
      end
    end

    context "for an AMA hearing with closed disposition" do
      %w[postponed cancelled scheduled_in_error].each do |disposition|
        context "#{disposition} hearing" do
          let(:ama_disposition) { disposition }
          let(:hearing) do
            create(:hearing, disposition: ama_disposition, hearing_day: video_hearing_day)
          end
          let!(:sent_event) do
            create(:sent_hearing_email_event, hearing: hearing)
          end

          it "returns nothing" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context "for a Legacy hearing with closed disposition" do
      %w[P C E].each do |disposition_code|
        context "#{VACOLS::CaseHearing::HEARING_DISPOSITIONS[disposition_code.to_sym]} virtual hearing" do
          let(:legacy_disposition) { disposition_code }
          let(:hearing) do
            create(
              :legacy_hearing,
              hearing_day: video_hearing_day,
              case_hearing: create(:case_hearing, hearing_disp: legacy_disposition)
            )
          end
          let!(:sent_event) do
            create(:sent_hearing_email_event, hearing: hearing)
          end

          it "returns nothing" do
            expect(subject).to be_empty
          end
        end
      end
    end
  end
end
