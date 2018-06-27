describe HearingDay do
  context "#create" do
    let(:hearing) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      HearingDay.create_hearing_day(hearing_hash)
    end

    context "add a hearing with only required attributes" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: VacolsHelper.local_date_with_utc_timezone,
          room_info: "1" }
      end

      it "creates hearing with required attributes" do
        expect(hearing.hearing_type).to eq "C"
        expect(hearing.hearing_date).to eq VacolsHelper.local_date_with_utc_timezone
        expect(hearing.room).to eq "1"
      end
    end

    context "add a video hearing" do
      let(:hearing_hash) do
        { hearing_type: "C",
          hearing_date: VacolsHelper.local_date_with_utc_timezone,
          regional_office: "RO89",
          room_info: "5" }
      end

      it "creates a video hearing" do
        expect(hearing.hearing_type).to eq "C"
        expect(hearing.hearing_date).to eq VacolsHelper.local_date_with_utc_timezone
        expect(hearing.folder_nr).to eq "VIDEO RO89"
        expect(hearing.room).to eq "5"
      end
    end
  end
end
