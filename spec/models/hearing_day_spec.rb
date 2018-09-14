describe HearingDay do
  context "#create" do
    let(:hearing) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      HearingDay.create_hearing_day(hearing_hash)
    end

    let(:test_hearing_date) do
      current_date = Date.today
      Time.use_zone("Eastern Time (US & Canada)") do
        Time.zone.local(current_date.year, current_date.month, current_date.day, 8, 30, 0).to_datetime
      end
    end

    context "add a hearing with only required attributes" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date,
          room_info: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S")).to eq test_hearing_date.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:room_info]).to eq "1"
      end
    end

    context "add a video hearing" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: test_hearing_date,
          regional_office: "RO89",
          room_info: "5" }
      end

      it "creates a video hearing" do
        expect(hearing[:hearing_type]).to eq "C"
        expect(hearing[:hearing_date].strftime("%Y-%m-%d %H:%M:%S")).to eq test_hearing_date.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing[:regional_office]).to eq "RO89"
        expect(hearing[:room_info]).to eq "5"
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
        expect(subject.size).to eq(358)
      end
    end
  end
end
