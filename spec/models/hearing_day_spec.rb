# frozen_string_literal: true

describe HearingDay do
  context "#create" do
    let(:hearing) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      HearingDay.create_hearing_day(hearing_hash)
    end

    let(:test_hearing_date_vacols) do
      current_date = Time.zone.today
      Time.use_zone("Eastern Time (US & Canada)") do
        Time.zone.local(current_date.year, current_date.month, current_date.day, 8, 30, 0).to_datetime
      end
    end

    let(:test_hearing_date_caseflow) do
      Time.zone.local(2019, 5, 15).to_date
    end

    context "add a hearing with only required attributes - VACOLS" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_vacols,
          room: "1"
        }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:request_type]).to eq HearingDay::REQUEST_TYPES[:central]
        expect(hearing[:scheduled_for].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d")
        expect(hearing[:room]).to eq "1"
      end
    end

    context "add a hearing with only required attributes - Caseflow" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          room: "1"
        }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:request_type]).to eq HearingDay::REQUEST_TYPES[:central]
        expect(hearing[:scheduled_for].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d")
        expect(hearing[:room]).to eq "1"
      end
    end

    context "add a video hearing - Caseflow" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          regional_office: "RO89",
          room: "5"
        }
      end

      it "creates a video hearing" do
        expect(hearing[:request_type]).to eq HearingDay::REQUEST_TYPES[:central]
        expect(hearing[:scheduled_for].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room]).to eq "5"
      end
    end
  end

  context "update hearing" do
    let!(:hearing_day) do
      FactoryBot.create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video], regional_office: "RO18")
    end
    let(:hearing_hash) do
      {
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Date.new(2019, 12, 7),
        regional_office: "RO89",
        room: "5",
        lock: true
      }
    end

    subject { hearing_day.update!(hearing_hash) }

    it "updates attributes" do
      subject

      updated_hearing_day = HearingDay.find(hearing_day.id).reload
      expect(updated_hearing_day.request_type).to eql(HearingDay::REQUEST_TYPES[:video])
      expect(updated_hearing_day.scheduled_for).to eql(Date.new(2019, 12, 7))
      expect(updated_hearing_day.regional_office).to eql("RO89")
      expect(updated_hearing_day.room).to eql("5")
      expect(updated_hearing_day.lock).to eql(true)
    end

    context "updates attributes in children hearings" do
      let!(:vacols_child_hearing) do
        FactoryBot.create(:case_hearing, vdkey: hearing_day.id, folder_nr: FactoryBot.create(:case).bfkey)
      end
      let!(:caseflow_child_hearing) { FactoryBot.create(:hearing, hearing_day_id: hearing_day.id) }

      before do
        RequestStore.store[:current_user] = OpenStruct.new(vacols_uniq_id: FactoryBot.create(:staff).slogid)
      end

      it "updates children hearings with a new room" do
        subject

        updated_vacols_child_hearing = vacols_child_hearing.reload
        expect(updated_vacols_child_hearing[:room]).to eql "5"
        updated_caseflow_child_hearing = caseflow_child_hearing.reload
        expect(updated_caseflow_child_hearing.room).to eql "5"
      end

      it "only tries to update the room, because that's all that changed in the hearing day" do
        expect_any_instance_of(LegacyHearing).to receive(:update!).with(room: "5")
        expect_any_instance_of(Hearing).to receive(:update!).with(room: "5")

        subject
      end

      context "both room and judge are changed" do
        let!(:judge) { FactoryBot.create(:user) }
        let!(:judge_role) { FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id) }
        let!(:hearing_hash) do
          {
            judge_id: judge.id,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Date.new(2019, 12, 7),
            regional_office: "RO89",
            room: "5",
            lock: true
          }
        end

        it "updates children hearings with a new room and judge" do
          subject

          updated_vacols_child_hearing = vacols_child_hearing.reload
          expect(updated_vacols_child_hearing[:room]).to eql "5"
          expect(updated_vacols_child_hearing.judge_id).to eql judge.vacols_attorney_id
          updated_caseflow_child_hearing = caseflow_child_hearing.reload
          expect(updated_caseflow_child_hearing.room).to eql "5"
          expect(updated_caseflow_child_hearing.judge).to eql judge
        end

        it "only tries to update the room and the judge, because that's all that changed in the hearing day" do
          expected_legacy_params = { room: "5", judge_id: judge.id }
          expect_any_instance_of(LegacyHearing).to receive(:update!).with(**expected_legacy_params)
          expected_ama_params = { room: "5", judge_id: judge.id }
          expect_any_instance_of(Hearing).to receive(:update!).with(**expected_ama_params)

          subject
        end
      end
    end
  end

  context "confirm_no_children_records" do
    let!(:hearing_day) { FactoryBot.create(:hearing_day) }
    let!(:hearing) { FactoryBot.create(:hearing, hearing_day: hearing_day) }

    it "returns an error if there are children records" do
      expect { hearing_day.reload.confirm_no_children_records }.to raise_error(HearingDay::HearingDayHasChildrenRecords)
    end
  end

  context "hearing day full" do
    context "the hearing day has 12 scheduled hearings" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day) }

      before do
        6.times do
          FactoryBot.create(:hearing, hearing_day: hearing_day)
          FactoryBot.create(:case_hearing, vdkey: hearing_day.id)
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(true)
      end
    end

    context "the hearing day has 12 closed hearings" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day) }

      before do
        6.times do
          FactoryBot.create(:hearing, hearing_day: hearing_day, disposition: "postponed")
          FactoryBot.create(:case_hearing, vdkey: hearing_day.id, hearing_disp: "C")
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(false)
      end
    end

    context "the hearing day is locked" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day, lock: true) }

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(true)
      end
    end
  end

  context "bulk persist" do
    let(:schedule_period) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      FactoryBot.create(:ro_schedule_period)
    end

    context "generate and persist hearing schedule" do
      before do
        HearingDay.create_schedule(schedule_period.algorithm_assignments)
      end

      subject { HearingDay.load_days(schedule_period.start_date, schedule_period.end_date) }

      it do
        expect(subject.size).to eql(442)
      end
    end
  end

  context "load Video days for a range date" do
    let!(:hearings) do
      [FactoryBot.create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today),
       FactoryBot.create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today + 1.day)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today + 1.day, "RO13") }

    it "gets hearings for a date range" do
      expect(subject.size).to eq 2
    end
  end

  context "load Central Office days for a range date" do
    let!(:hearings) do
      [FactoryBot.create(:hearing_day, scheduled_for: Time.zone.today),
       FactoryBot.create(:hearing_day, scheduled_for: Time.zone.today + 1.day),
       FactoryBot.create(:hearing_day, scheduled_for: Time.zone.today + 2.days)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today + 2.days, HearingDay::REQUEST_TYPES[:central]) }

    it "should load all three hearing days" do
      expect(subject.size).to eq 3
    end
  end

  context "Video Hearing parent and child rows for a date range" do
    let(:vacols_case) do
      FactoryBot.create(
        :case,
        folder: FactoryBot.create(:folder, tinum: "docket-number"),
        bfregoff: "RO13",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { FactoryBot.create(:staff, stafkey: "RO13", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearing_day) do
      FactoryBot.create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today)
    end
    let!(:hearing) do
      FactoryBot.create(:case_hearing, folder_nr: appeal.vacols_id, vdkey: hearing_day.id)
    end

    context "get parent and children structure" do
      subject do
        HearingDay.open_hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
                                                        hearing.hearing_date.beginning_of_day + 10, staff.stafkey)
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:request_type]).to eq HearingDay::REQUEST_TYPES[:video]
        expect(subject[0][:hearings][0]["appeal_id"]).to eq appeal.id
      end
    end
  end

  context "Video Hearings returns video hearings that are not postponed or cancelled" do
    let(:vacols_case) do
      FactoryBot.create(
        :case,
        folder: FactoryBot.create(:folder, tinum: "docket-number"),
        bfregoff: "RO13",
        bfcurloc: "57",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:appeal) do
      FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { FactoryBot.create(:staff, stafkey: "RO13", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearing) do
      FactoryBot.create(:case_hearing, folder_nr: appeal.vacols_id)
    end
    let(:vacols_case2) do
      FactoryBot.create(
        :case,
        bfregoff: "RO13",
        bfcurloc: "57",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:appeal2) do
      FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: vacols_case2)
    end
    let!(:hearing2) do
      FactoryBot.create(
        :case_hearing, :disposition_postponed, folder_nr: appeal2.vacols_id, vdkey: hearing.vdkey
      )
    end

    subject do
      HearingDay.open_hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
                                                      hearing.hearing_date.beginning_of_day + 1.day, staff.stafkey)
    end

    context "get video hearings neither postponed or cancelled" do
      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:request_type]).to eq HearingDay::REQUEST_TYPES[:video]
        expect(subject[0][:hearings][0]["appeal_id"]).to eq appeal.id
        expect(subject[0][:hearings][0]["hearing_disp"]).to eq nil
      end
    end

    context "When there are multiple hearings and multiple days" do
      let(:appeal_today) do
        FactoryBot.create(
          :legacy_appeal, :with_veteran, vacols_case: FactoryBot.create(:case)
        )
      end
      let!(:second_hearing_today) do
        FactoryBot.create(:case_hearing, vdkey: hearing.vdkey, folder_nr: appeal_today.vacols_id)
      end
      let(:appeal_tomorrow) do
        FactoryBot.create(
          :legacy_appeal, :with_veteran, vacols_case: FactoryBot.create(:case)
        )
      end
      let!(:hearing_tomorrow) do
        FactoryBot.create(
          :case_hearing, hearing_date: Time.zone.tomorrow, folder_nr: appeal_tomorrow.vacols_id
        )
      end
      let!(:ama_hearing_day) do
        FactoryBot.create(:hearing_day,
                          request_type: HearingDay::REQUEST_TYPES[:video],
                          scheduled_for: Time.zone.now,
                          regional_office: staff.stafkey)
      end
      let!(:ama_appeal) { FactoryBot.create(:appeal) }
      let!(:ama_hearing) { FactoryBot.create(:hearing, :with_tasks, hearing_day: ama_hearing_day, appeal: ama_appeal) }

      it "returns hearings are mapped to days" do
        expect(subject.size).to eq 3
        expect(subject[0][:hearings][0]["appeal_id"]).to eq ama_appeal.id
        expect(subject[1][:hearings][0]["appeal_id"]).to eq appeal_tomorrow.id
        expect(subject[2][:hearings].size).to eq 2
        expect(subject[2][:request_type]).to eq HearingDay::REQUEST_TYPES[:video]
        expect(subject[2][:hearings][0]["appeal_id"]).to eq appeal.id
        expect(subject[2][:hearings][0]["hearing_disp"]).to eq nil
        expect(subject[2][:hearings][1]["appeal_id"]).to eq appeal_today.id
      end
    end

    context "When there are hearing days that are filled up" do
      before do
        allow(HearingDay).to receive(:fetch_hearing_day_slots).and_return(1, 5)
      end

      let(:appeal_today) do
        FactoryBot.create(
          :legacy_appeal, :with_veteran, vacols_case: FactoryBot.create(:case)
        )
      end
      let(:appeal_tomorrow) do
        FactoryBot.create(
          :legacy_appeal, :with_veteran, vacols_case: FactoryBot.create(:case)
        )
      end
      let!(:hearing_tomorrow) do
        FactoryBot.create(
          :case_hearing, hearing_date: Time.zone.tomorrow, folder_nr: appeal_tomorrow.vacols_id
        )
      end

      it "only returns hearing days that are not full" do
        expect(subject.size).to eq 1
      end
    end
  end

  context "Central Office parent and child rows for a date range" do
    let(:vacols_case) do
      FactoryBot.create(
        :case,
        folder: FactoryBot.create(:folder, tinum: "docket-number"),
        bfregoff: "RO04",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { FactoryBot.create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing) do
      FactoryBot.create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: appeal.vacols_id)
    end

    context "get parent and children structure" do
      subject do
        HearingDay.open_hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
                                                        hearing.hearing_date.beginning_of_day + 10,
                                                        HearingDay::REQUEST_TYPES[:central])
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:request_type]).to eq HearingDay::REQUEST_TYPES[:central]
        expect(subject[0][:hearings][0]["appeal_id"]).to eq appeal.id
      end
    end
  end

  context ".fetch_hearing_day_slots" do
    subject { HearingDay.fetch_hearing_day_slots(regional_office) }

    context "returns slots for Winston-Salem" do
      let(:regional_office) { "RO18" }

      it { is_expected.to eq 12 }
    end

    context "returns slots for Denver" do
      let(:regional_office) { "RO37" }

      it { is_expected.to eq 10 }
    end

    context "returns slots for Los_Angeles" do
      let(:regional_office) { "RO44" }

      it { is_expected.to eq 8 }
    end
  end
end
