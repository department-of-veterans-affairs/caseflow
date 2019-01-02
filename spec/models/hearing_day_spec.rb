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
        { hearing_type: "C",
          hearing_date: test_hearing_date_vacols,
          room: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d")
        expect(hearing[:room]).to eq "1"
      end
    end

    context "add a hearing with only required attributes - Caseflow" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_caseflow,
          room: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d")
        expect(hearing[:room]).to eq "1"
      end
    end

    context "add a video hearing - VACOLS" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_vacols,
          regional_office: "RO89",
          room: "5" }
      end

      it "creates a video hearing" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_vacols.to_date.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room]).to eq "5"
      end
    end

    context "add a video hearing - Caseflow" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_caseflow,
          regional_office: "RO89",
          room: "5" }
      end

      it "creates a video hearing" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room]).to eq "5"
      end
    end
  end

  context "update hearing" do
    let(:hearing_day) { create(:hearing_day, hearing_type: "V") }
    let(:hearing_hash) do
      { hearing_type: "V",
        hearing_date: Date.new(2019, 12, 7),
        regional_office: "RO89",
        room: "5",
        lock: true }
    end

    it "updates attributes" do
      HearingDay.find(hearing_day.id).update!(hearing_hash)
      updated_hearing_day = HearingDay.find(hearing_day.id).reload
      expect(updated_hearing_day.hearing_type).to eql("V")
      expect(updated_hearing_day.hearing_date).to eql(Date.new(2019, 12, 7))
      expect(updated_hearing_day.regional_office).to eql("RO89")
      expect(updated_hearing_day.room).to eql("5")
      expect(updated_hearing_day.lock).to eql(true)
    end

    context "updates attributes in children hearings" do
      before do
        RequestStore.store[:current_user] = OpenStruct.new(vacols_uniq_id: create(:staff).slogid)
      end
      let!(:child_hearing) { create(:case_hearing, vdkey: hearing_day.id, folder_nr: create(:case).bfkey) }

      it "updates children hearings" do
        HearingDay.find(hearing_day.id).update!(hearing_hash)
        updated_child_hearing = child_hearing.reload
        expect(updated_child_hearing[:room]).to eql "5"
      end
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
    let(:hearings) do
      [create(:case_hearing),
       create(:case_hearing)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today, "RO13") }

    it "gets hearings for a date range" do
      expect(subject.size).to eq 2
    end
  end

  context "load Central Office days for a range date" do
    let!(:hearings) do
      [create(:case_hearing, hearing_type: "C", folder_nr: nil),
       create(:case_hearing, hearing_type: "C", folder_nr: nil),
       create(:case_hearing, hearing_type: "C", folder_nr: nil)]
    end

    subject { HearingDay.load_days(Time.zone.today, Time.zone.today, "C") }

    it "gets hearings for a date range" do
      hearings
      expect(subject.size).to eq 2
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
        HearingDay.load_days_with_open_hearing_slots((hearing.hearing_date - 1).beginning_of_day,
                                                     hearing.hearing_date.beginning_of_day + 10, staff.stafkey)
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:hearing_type]).to eq "V"
        expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
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
        bfdocind: "V"
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
        folder: create(:folder),
        bfregoff: "RO13",
        bfcurloc: "57",
        bfdocind: "V"
      )
    end
    let(:appeal2) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case2)
    end
    let!(:hearing2) do
      create(:case_hearing, :disposition_postponed, folder_nr: appeal2.vacols_id, vdkey: parent_hearing.hearing_pkseq)
    end

    context "get video hearings neither postponed or cancelled" do
      subject do
        HearingDay.load_days_with_open_hearing_slots((hearing.hearing_date - 1).beginning_of_day,
                                                     hearing.hearing_date.beginning_of_day + 10, staff.stafkey)
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:hearing_type]).to eq "V"
        expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
        expect(subject[0][:hearings][0][:hearing_disp]).to eq nil
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
      create(:case_hearing, hearing_type: "C", folder_nr: appeal.vacols_id)
    end

    context "get parent and children structure" do
      subject do
        HearingDay.load_days_with_open_hearing_slots((hearing.hearing_date - 1).beginning_of_day,
                                                     hearing.hearing_date.beginning_of_day + 10, "C")
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:hearing_type]).to eq "C"
        expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
      end
    end
  end

  context "Central Office return only slots with folder_nr null (available)" do
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
    let!(:hearing) do
      create(:case_hearing, hearing_type: "C", folder_nr: appeal.vacols_id)
    end
    let!(:hearing2) do
      create(:case_hearing, hearing_type: "C")
    end

    context "get CO hearings with no veterans assigned to them" do
      subject do
        HearingDay.load_days_with_open_hearing_slots((hearing.hearing_date - 1).beginning_of_day,
                                                     hearing.hearing_date.beginning_of_day + 10, "C")
      end

      it "returns nested hash structure" do
        expect(subject.size).to eq 1
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:hearing_type]).to eq "C"
        expect(subject[0][:hearings].size).to eq 1
        expect(subject[0][:hearings][0][:vacols_id]).to eql(hearing.hearing_pkseq.to_s)
      end
    end
  end
end
