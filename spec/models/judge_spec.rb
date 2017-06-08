describe Judge do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context "#upcoming_dockets" do
    subject { Judge.new(user).upcoming_dockets }

    let(:user) { Generators::User.create }
    let!(:hearing_later_date) { Generators::Hearing.create(user: user, date: 3.days.from_now) }
    let!(:hearing) { Generators::Hearing.create(user: user, date: 1.day.from_now) }
    let!(:hearing_same_date) { Generators::Hearing.create(user: user, date: 1.day.from_now) }
    let!(:hearing_another_judge) { Generators::Hearing.create(user: Generators::User.create, date: 2.days.from_now) }

    it "returns an array of hearing dockets in chronological order" do
      expect(subject.length).to eq(2)

      expect(subject.first.class).to eq(HearingDocket)

      expect(subject.first.date).to eq(1.day.from_now)
      expect(subject.first.hearings.first).to eq(hearing)

      expect(subject.last.date).to eq(3.days.from_now)
      expect(subject.last.hearings.first).to eq(hearing_later_date)
    end

    it "returns dockets with hearings grouped by date" do
      expect(subject.first.hearings.map(&:date)).to all(eq(subject.first.date))
      expect(subject.last.hearings.map(&:date)).to all(eq(subject.last.date))
    end

    it "excludes hearings for another judge" do
      hearing_ids = subject.map { |d| d.hearings.map(&:id) }.flatten
      expect(hearing_ids).to_not include(hearing_another_judge.id)
    end
  end

  context "#docket" do
    subject { Judge.new(user).docket(date) }

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
        expect(subject[index][:vbms_id]).to eq(hearings[index].appeal.vbms_id)
        expect(subject[index][:vacols_id]).to eq(hearings[index].vacols_id)
        expect(subject[index][:date]).to eq(hearings[index].date)
        expect(subject[index][:type]).to eq(hearings[index].request_type)
        expect(subject[index][:venue]).to eq(hearings[index].venue)
        expect(subject[index][:appellant]).to eq(hearings[index].appellant_name)
        expect(subject[index][:representative]).to eq(hearings[index].appeal.representative)
      end
    end
  end
end
