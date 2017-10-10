describe HearingDocket do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  let!(:appeal) do
    Generators::Appeal.create(vbms_id: "333222333S")
  end

  let!(:hearing) do
    Generators::Hearing.create(appeal: appeal)
  end

  let(:docket) do
    HearingDocket.new(
      date: 7.days.from_now,
      type: :video,
      regional_office_name: hearing.regional_office_name,
      regional_office_key: "RO31",
      hearings: [
        hearing
      ]
    )
  end

  context ".from_hearings" do
    subject { HearingDocket.from_hearings(hearings) }

    let(:hearings) do
      [Generators::Hearing.create(date: 5.minutes.ago), Generators::Hearing.create(date: 10.minutes.ago)]
    end

    it "returns the earliest date" do
      expect(subject.date).to eq 10.minutes.ago
    end
  end

  context "#slots" do
    subject { docket.slots }

    context "should use the default number of slots for the regional office" do
      it { is_expected.to eq 9 }
    end
  end

  context "#to_hash" do
    subject { docket.to_hash.symbolize_keys }

    it "returns a hash" do
      expect(subject.class).to eq(Hash)
      expect(subject[:date]).to eq(docket.date)
      expect(subject[:hearings_array].length).to eq(1)
      expect(subject[:type]).to eq(:video)
      expect(subject[:regional_office_name]).to eq(hearing.regional_office_name)
      expect(subject[:slots]).to eq 9
    end
  end

  context "#attributes" do
    subject { docket.attributes }
    it "returns a hash" do
      expect(subject.class).to eq(Hash)
    end
  end
end
