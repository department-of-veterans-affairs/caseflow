describe Judge do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".upcoming_dockets" do
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
end
