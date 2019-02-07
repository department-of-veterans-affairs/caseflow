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
        { request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_vacols,
          room: "1" }
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
        { request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          room: "1" }
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
        { request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          regional_office: "RO89",
          room: "5" }
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
    let(:hearing_day) { create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video]) }
    let(:hearing_hash) do
      { request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Date.new(2019, 12, 7),
        regional_office: "RO89",
        room: "5",
        lock: true }
    end

    it "updates attributes" do
      HearingDay.find(hearing_day.id).update!(hearing_hash)
      updated_hearing_day = HearingDay.find(hearing_day.id).reload
      expect(updated_hearing_day.request_type).to eql(HearingDay::REQUEST_TYPES[:video])
      expect(updated_hearing_day.scheduled_for).to eql(Date.new(2019, 12, 7))
      expect(updated_hearing_day.regional_office).to eql("RO89")
      expect(updated_hearing_day.room).to eql("5")
      expect(updated_hearing_day.lock).to eql(true)
    end

    context "updates attributes in children hearings" do
      before do
        RequestStore.store[:current_user] = OpenStruct.new(vacols_uniq_id: create(:staff).slogid)
      end
      let!(:vacols_child_hearing) { create(:case_hearing, vdkey: hearing_day.id, folder_nr: create(:case).bfkey) }
      let!(:caseflow_child_hearing) { create(:hearing, hearing_day: hearing_day, room: "5") }

      it "updates children hearings" do
        HearingDay.find(hearing_day.id).update!(hearing_hash)
        updated_vacols_child_hearing = vacols_child_hearing.reload
        expect(updated_vacols_child_hearing[:room]).to eql "5"
        updated_caseflow_child_hearing = caseflow_child_hearing.reload
        expect(updated_caseflow_child_hearing.room).to eql "5"
      end
    end
  end

  context "confirm_no_children_records" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:hearing) { create(:hearing, hearing_day: hearing_day) }

    it "returns an error if there are children records" do
      expect { hearing_day.confirm_no_children_records }.to raise_error(HearingDay::HearingDayHasChildrenRecords)
    end
  end

  context "bulk persist" do
    let(:schedule_period) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      create(:ro_schedule_period)
    end

    context "generate and persist hearing schedule" do
      before do
        HearingDay.create_schedule(schedule_period.algorithm_assignments)
      end

      subject { VACOLS::CaseHearing.load_days_for_range(schedule_period.start_date, schedule_period.end_date) }

      it do
        expect(subject.size).to eql(358)
      end
    end
  end

  context "load Video days for a range date" do
    let!(:hearings) do
      [create(:case_hearing),
       create(:case_hearing)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today, "RO13") }

    it "gets hearings for a date range" do
      expect(subject[:vacols_hearings].size).to eq 2
    end
  end

  context "load Central Office days for a range date" do
    let!(:hearings) do
      [create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: nil),
       create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: nil),
       create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: nil)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today, HearingDay::REQUEST_TYPES[:central]) }

    it "shouldn't load any since we're past HearingDay::CASEFLOW_CO_PARENT_DATE" do
      expect(subject[:vacols_hearings].size).to eq 0
    end
  end

  context "Video Hearing parent and child rows for a date range" do
    let(:vacols_case) do
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO13",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { create(:staff, stafkey: "RO13", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing) do
      create(:case_hearing, folder_nr: appeal.vacols_id)
    end
    let(:parent_hearing) do
      VACOLS::CaseHearing.find(hearing.vdkey)
    end

    context "get parent and children structure" do
      subject do
        HearingDay.hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
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
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO13",
        bfcurloc: "57",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { create(:staff, stafkey: "RO13", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearing) do
      create(:case_hearing, folder_nr: appeal.vacols_id)
    end
    let(:parent_hearing) do
      VACOLS::CaseHearing.find(hearing.vdkey)
    end
    let(:vacols_case2) do
      create(
        :case,
        bfregoff: "RO13",
        bfcurloc: "57",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:appeal2) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case2)
    end
    let!(:hearing2) do
      create(:case_hearing, :disposition_postponed, folder_nr: appeal2.vacols_id, vdkey: parent_hearing.hearing_pkseq)
    end

    subject do
      HearingDay.hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
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
        create(
          :legacy_appeal, :with_veteran, vacols_case: create(:case)
        )
      end
      let!(:second_hearing_today) do
        create(:case_hearing, vdkey: parent_hearing.hearing_pkseq, folder_nr: appeal_today.vacols_id)
      end
      let(:appeal_tomorrow) do
        create(
          :legacy_appeal, :with_veteran, vacols_case: create(:case)
        )
      end
      let!(:hearing_tomorrow) do
        create(
          :case_hearing, hearing_date: Time.zone.tomorrow, folder_nr: appeal_tomorrow.vacols_id
        )
      end
      let!(:ama_hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: Time.zone.now,
               regional_office: staff.stafkey)
      end
      let!(:ama_appeal) { create(:appeal) }
      let!(:ama_hearing) { create(:hearing, hearing_day: ama_hearing_day, appeal: ama_appeal) }

      it "returns hearings are mapped to days" do
        expect(subject.size).to eq 3
        expect(subject[0][:hearings][0]["appeal_id"]).to eq ama_appeal.id
        expect(subject[1][:hearings].size).to eq 2
        expect(subject[1][:request_type]).to eq HearingDay::REQUEST_TYPES[:video]
        expect(subject[1][:hearings][0]["appeal_id"]).to eq appeal.id
        expect(subject[1][:hearings][0]["hearing_disp"]).to eq nil
        expect(subject[1][:hearings][1]["appeal_id"]).to eq appeal_today.id
        expect(subject[2][:hearings][0]["appeal_id"]).to eq appeal_tomorrow.id
      end
    end

    context "When there are hearing days that are filled up" do
      before do
        allow(HearingDayRepository).to receive(:fetch_hearing_day_slots).and_return(1, 5)
      end

      let(:appeal_today) do
        create(
          :legacy_appeal, :with_veteran, vacols_case: create(:case)
        )
      end
      let(:appeal_tomorrow) do
        create(
          :legacy_appeal, :with_veteran, vacols_case: create(:case)
        )
      end
      let!(:hearing_tomorrow) do
        create(
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
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO04",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing) do
      create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central],
                            folder_nr: appeal.vacols_id)
    end

    context "get parent and children structure" do
      subject do
        HearingDay.hearing_days_with_hearings_hash((hearing.hearing_date - 1).beginning_of_day,
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
end
