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

  context "#upcoming_for_judge" do
    subject { HearingDocket.upcoming_for_judge(user) }

    let(:user) { Generators::User.create }
    let!(:hearing_later_date) { Generators::Hearing.create(user: user, date: 3.days.from_now) }
    let!(:hearing) { Generators::Hearing.create(user: user, date: 1.day.from_now) }

    it "returns an array of hearing dockets in chronological order" do
      expect(subject.length).to eq(2)

      expect(subject.first.class).to eq(HearingDocket)

      expect(subject.first.date).to eq(1.day.from_now)
      expect(subject.first.hearings.first).to eq(hearing)

      expect(subject.last.date).to eq(3.days.from_now)
      expect(subject.last.hearings.first).to eq(hearing_later_date)
    end
  end

  context "#docket_for_judge" do
    subject { HearingDocket.docket_for_judge(user, date) }

    let(:user) { Generators::User.create }
    let(:date) { Time.zone.now.strftime("%Y-%m-%d") }

    let!(:hearings) do
      [
        Generators::Hearing.create(user: user, date: 1.hour.from_now),
        Generators::Hearing.create(user: user, date: 2.hours.from_now)
      ]
    end

    it "returns a docket's hearings in chronological order" do
      [0, 1].each do |index|
        expect(subject[index][:date]).to eq(hearings[index].date)
        expect(subject[index][:type]).to eq(HearingDocket.hearing_type(hearings[index].type))
        expect(subject[index][:venue]).to eq(hearings[index].venue)
        expect(subject[index][:appellant]).to eq(HearingDocket.appellant(hearings[index].appeal))
        expect(subject[index][:appellantId]).to eq(hearings[index].appeal.vbms_id)
        expect(subject[index][:representative]).to eq(hearings[index].appeal.representative)
      end
    end

    it "raises a NoDocket exception on error" do
      expect { HearingDocket.docket_for_judge(user, "Bad Date") }.to raise_error(HearingDocket::NoDocket)
    end
  end

  context "#hearing_type" do
    it "returns 'CO' for :central_office" do
      expect(HearingDocket.hearing_type(:central_office)).to eql("CO")
    end

    it "otherwise returns type in sentence case" do
      expect(HearingDocket.hearing_type(:video)).to eql("Video")
    end
  end

  context "#appellant" do
    let(:appeal) { Generators::Appeal.create(vacols_record: :full_grant_decided) }

    it "returns appellant's name in format '<lastname>, <firstname>'" do
      expect(HearingDocket.appellant(appeal)).to eql(
        "#{appeal.appellant_last_name}, #{appeal.appellant_first_name}"
      )
    end
  end
end
