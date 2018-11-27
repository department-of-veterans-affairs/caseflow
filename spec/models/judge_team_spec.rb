describe JudgeTeam do
  let(:judge) { FactoryBot.create(:user) }

  describe ".create_for_judge" do
    context "when user is not already an admin of an existing JudgeTeam" do
      it "should create a new organization and make the user an admin of that group" do
        expect(judge.organizations.length).to eq(0)

        expect { JudgeTeam.create_for_judge(judge) }.to_not raise_error
        judge.reload

        expect(judge.organizations.length).to eq(1)
        expect(judge.administered_teams.length).to eq(1)
        expect(judge.administered_teams.first.class).to eq(JudgeTeam)
      end
    end
  end

  describe ".for_judge" do
    let(:user) { FactoryBot.create(:user) }

    context "when user is admin of a non-JudgeTeam organization" do
      before { OrganizationsUser.make_user_admin(user, FactoryBot.create(:organization)) }

      it "should return nil" do
        expect(JudgeTeam.for_judge(user)).to eq(nil)
      end
    end

    context "when user is member of JudgeTeam" do
      let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
      before { OrganizationsUser.add_user_to_organization(user, judge_team) }

      it "should return nil" do
        expect(JudgeTeam.for_judge(user)).to eq(nil)
      end
    end

    context "when user is admin of JudgeTeam" do
      let!(:judge_team) { JudgeTeam.create_for_judge(user) }

      it "should return judge team" do
        expect(JudgeTeam.for_judge(user)).to eq(judge_team)
      end
    end

    # Limitation of the current approach is that users are effectively limited to being the admin of a single JudgeTeam.
    context "when user is admin of multiple JudgeTeams" do
      let!(:first_judge_team) { JudgeTeam.create_for_judge(user) }
      let!(:second_judge_team) { JudgeTeam.create_for_judge(user) }

      it "should return first judge team even when they admin two judge teams" do
        expect(JudgeTeam.for_judge(user)).to eq(first_judge_team)
        expect(user.administered_teams.length).to eq(2)
      end
    end
  end

  describe ".can_receive_task?" do
    it "should return false because judge teams should not have tasks assigned to them in the web UI" do
      expect(JudgeTeam.create_for_judge(judge).can_receive_task?(nil)).to eq(false)
    end
  end
end
