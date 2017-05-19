describe HearingDocket do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  let(:docket) do
    HearingDocket.new(
      date: 7.days.from_now,
      type: :video,
      venue: VACOLS::RegionalOffice::SATELLITE_OFFICES.values.first,
      hearings: [
        Generators::Hearing.build
      ]
    )
  end

  context "#to_hash" do
    subject { docket.to_hash.symbolize_keys }

    it "returns a hash" do
      expect(subject.class).to eq(Hash)
      expect(subject[:date]).to eq(docket.date)
      expect(subject[:hearings].length).to eq(1)
      expect(subject[:type]).to eq(:video)
      expect(subject[:venue][:city]).to eq("San Antonio")
    end
  end

  context "#attributes" do
    subject { docket.attributes }
    it "returns a hash" do
      expect(subject.class).to eq(Hash)
    end
  end

  context ".upcoming_from_judge" do
    let(:user) { Generators::User.create }
    let(:hearing) { Generators::Hearing.create(user: user) }
    subject { HearingDocket.upcoming_for_judge(user) }
    before do
      hearing # ensure hearing is created
    end

    it "returns an array of hearing dockets" do
      expect(subject.class).to eq(Array)
      expect(subject.first.class).to eq(HearingDocket)
      expect(subject.first.hearings.first).to eq(hearing)
    end
  end
end
