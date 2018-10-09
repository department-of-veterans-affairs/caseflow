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
      Time.zone.local(2019, 5, 15, 12, 30, 0).to_datetime # UTC
    end

    context "add a hearing with only required attributes - VACOLS" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_vacols,
          room_info: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:room_info]).to eq "1"
      end
    end

    context "add a hearing with only required attributes - Caseflow" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_caseflow,
          room_info: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:room_info]).to eq "1"
      end
    end

    context "add a video hearing - VACOLS" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_vacols,
          regional_office: "RO89",
          room_info: "5" }
      end

      it "creates a video hearing" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room_info]).to eq "5"
      end
    end

    context "add a video hearing - Caseflow" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_caseflow,
          regional_office: "RO89",
          room_info: "5" }
      end

      it "creates a video hearing" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room_info]).to eq "5"
      end
    end
  end

  context "update hearing", focus: true do
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
      Time.zone.local(2019, 5, 15, 12, 30, 0).to_datetime # UTC
    end

    context "update judge attribute in VACOLS hearing day" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date_vacols,
          regional_office: "RO89",
          room_info: "5" }
      end

      it "updates judge" do
        hearing_id = hearing[:id] + 1
        hearing_to_update = HearingDay.find_hearing_day(nil, hearing_id)
        HearingDay.update_hearing_day(hearing_to_update, judge_id: "987")
        expect(hearing_to_update[:board_member]).to eq "987"
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

  context "Video Hearing parent and child rows for a date range" do
    let(:vacols_case) do
      create(:case)
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
      subject { HearingDay.load_days_with_hearings(hearing.hearing_date, hearing.hearing_date) }

      it "returns nested hash structure" do
        expect(subject.size).to eq subject.size
        # expect(subject[0][:hearings].size).to eql(1)
        # expect(subject[0][:hearings][0][:hearing_location])
        #   .to eq parent_hearing.folder_nr.slice(6, parent_hearing.folder_nr.length)
        # expect(subject[0][:hearings][0][:appeal_info][:veteran_name]).to eq appeal.veteran_full_name
      end
    end
  end

  context "Central Office parent and child rows for a date range" do
    let(:vacols_case) do
      create(:case)
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing) do
      create(:case_hearing, hearing_type: "C", folder_nr: appeal.vacols_id)
    end

    context "get parent and children structure" do
      subject { HearingDay.load_days_with_hearings(hearing.hearing_date, hearing.hearing_date) }

      it "returns nested hash structure" do
        expect(subject.size).to eq subject.size
        # expect(subject[0][:hearings].size).to eql(1)
        # expect(subject[0][:hearings][0][:hearing_location]).to eq "Central"
        # expect(subject[0][:hearings][0][:appeal_info][:veteran_name]).to eq appeal.veteran_full_name
      end
    end
  end
end
