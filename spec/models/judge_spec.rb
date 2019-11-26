# frozen_string_literal: true

describe Judge, :postgres do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
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

  context "#attorneys" do
    let(:user) { create(:user) }
    let(:judge) { Judge.new(user) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:member_count) { 5 }
    let(:attorneys) { create_list(:user, member_count) }

    before do
      attorneys.each do |u|
        judge_team.add_user(u)
      end
    end

    subject { judge.attorneys }

    it "returns a list of the judge's attorneys" do
      judge.user.reload
      expect(subject).to match_array attorneys
    end
  end
end
