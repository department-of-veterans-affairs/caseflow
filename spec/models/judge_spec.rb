describe Judge do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "UTC"
  end

  context ".upcoming_dockets" do
    subject { Judge.new(user).upcoming_dockets }

    let(:user) { Generators::User.create }
    let!(:hearing)            { create(:legacy_hearing, user: user, date: 1.day.from_now) }
    let!(:hearing_same_date)  { create(:legacy_hearing, user: user, date: 1.day.from_now + 2.hours) }
    let!(:hearing_later_date) { create(:legacy_hearing, user: user, date: 3.days.from_now) }
    let!(:hearing_another_judge) { create(:legacy_hearing, user: Generators::User.create, date: 2.days.from_now) }

    it "returns a hash of hearing dockets indexed by date" do
      keys = subject.keys.sort

      expect(keys.length).to eq(2)

      expect(keys.first.to_date).to eq(1.day.from_now.to_date)
      expect(subject[keys.first].hearings.first).to eq(hearing)

      expect(keys.last.to_date).to eq(3.days.from_now.to_date)
      expect(subject[keys.last].hearings.first).to eq(hearing_later_date)
    end

    it "returns dockets with hearings grouped by date" do
      keys = subject.keys.sort

      # to_date() normalizes on YYYY-MM-DD
      first_dates = subject[keys.first].hearings.map { |hash| hash.date.to_date }
      last_dates = subject[keys.last].hearings.map { |hash| hash.date.to_date }

      expect(first_dates).to all(eq(keys.first.to_date))
      expect(last_dates).to all(eq(keys.last.to_date))
    end

    it "returns hearings with IDs" do
      hearing_ids = subject.map { |key, _v| subject[key].hearings.map(&:id) }.flatten
      expect(hearing_ids.compact.size).to eq 3
    end

    it "excludes hearings for another judge" do
      hearing_ids = subject.map { |key, _v| subject[key].hearings.map(&:id) }.flatten
      expect(hearing_ids).to_not include(hearing_another_judge.id)
    end
  end

  context ".list_all" do
    it "should cache the values" do
      expect(JudgeRepository).to receive(:find_all_judges).once
      Judge.list_all
      # call a second time, should get from the cache
      Judge.list_all
    end
  end

  context ".list_all_with_name_and_id" do
    it "should cache the values" do
      expect(JudgeRepository).to receive(:find_all_judges_with_name_and_id).once
      Judge.list_all_with_name_and_id
      # call a second time, should get from the cache
      Judge.list_all_with_name_and_id
    end
  end

  context "#docket?" do
    let(:user) { FactoryBot.create(:user) }
    let(:judge) { Judge.new(user) }
    let(:date) { Time.zone.now }
    let(:out_of_range_date) { date - 300.years }
    let!(:hearings) do
      [
        create(:legacy_hearing, user: user, date: 1.hour.from_now)
      ]
    end

    it "returns true if docket exists" do
      expect(judge.docket?(date)).to be_truthy
    end

    it "returns false if docket does not exist" do
      expect(judge.docket?(out_of_range_date)).to be_falsey
    end
  end

  context "#attorneys" do
    let(:user) { FactoryBot.create(:user) }
    let(:judge) { Judge.new(user) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:member_count) { 5 }
    let(:attorneys) { FactoryBot.create_list(:user, member_count) }

    before do
      attorneys.each do |u|
        OrganizationsUser.add_user_to_organization(u, judge_team)
      end
    end

    subject { judge.attorneys }

    it "returns a list of the judge's attorneys" do
      expect(subject).to match_array attorneys
    end
  end
end
