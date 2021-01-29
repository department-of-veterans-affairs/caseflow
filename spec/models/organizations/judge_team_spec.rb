# frozen_string_literal: true

describe JudgeTeam, :postgres do
  let(:judge) { create(:user) }

  context "scope" do
    context "pushed_priority_cases_allowed" do
      let(:judge2) { create(:user) }
      let!(:judge_team_available) { JudgeTeam.create_for_judge(judge) }
      let(:judge_team_unavailable) { JudgeTeam.create_for_judge(judge2) }

      before { judge_team_unavailable.update(accepts_priority_pushed_cases: false) }

      it "returns only the available JudgeTeams" do
        expect(JudgeTeam.pushed_priority_cases_allowed).to eq([judge_team_available])
      end
    end
  end

  shared_examples "has the judge and attorneys" do
    describe ".judge" do
      it "returns the team judge" do
        expect(judge_team.judge).to eq judge.user
      end
    end

    describe ".attorneys" do
      it "returns the team attorneys" do
        expect(judge_team.attorneys).to match_array attorneys
      end
    end
  end

  shared_examples "successful judge team creation" do
    it "creates a new organization and makes the user an admin of that group" do
      expect(JudgeTeam.for_judge(judge)).to eq(nil)

      expect { subject }.to_not raise_error
      judge.reload

      expect(JudgeTeam.for_judge(judge)).not_to eq(nil)
      expect(JudgeTeam.for_judge(judge).accepts_priority_pushed_cases).to eq(true)
    end
  end

  shared_examples "judge team already exists" do
    it "raises an error and fails to create the new JudgeTeam" do
      judge.reload
      expect { subject }.to raise_error(Caseflow::Error::DuplicateJudgeTeam)
    end
  end

  describe "feature use_judge_team_roles not activated" do
    describe ".create_for_judge" do
      subject { JudgeTeam.create_for_judge(judge) }

      context "when user is not already an admin of an existing JudgeTeam" do
        it_behaves_like "successful judge team creation"
      end

      context "when a JudgeTeam already exists for this user" do
        before { JudgeTeam.create_for_judge(judge) }

        it_behaves_like "judge team already exists"
      end
    end

    describe ".for_judge" do
      let(:user) { create(:user) }

      context "when user is admin of a non-JudgeTeam organization" do
        before { OrganizationsUser.make_user_admin(user, create(:organization)) }

        it "returns nil" do
          expect(JudgeTeam.for_judge(user)).to eq(nil)
        end
      end

      context "when user is non-admin member of JudgeTeam" do
        let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
        before { judge_team.add_user(user) }

        it "returns nil" do
          expect(JudgeTeam.for_judge(user)).to eq(nil)
        end
      end

      context "when user is admin of JudgeTeam" do
        let!(:judge_team) { JudgeTeam.create_for_judge(user) }

        it "returns judge team" do
          user.reload
          expect(JudgeTeam.for_judge(user)).to eq(judge_team)
        end
      end

      # Limitation of the current approach is that users are effectively limited to being the admin of
      # a single JudgeTeam.
      context "when user is admin of multiple JudgeTeams" do
        let!(:first_judge_team) { JudgeTeam.create_for_judge(user) }
        let!(:second_judge_team) do
          JudgeTeam.create!(name: "#{user.css_id}_2", url: "#{user.css_id.downcase}_2").tap do |org|
            OrganizationsUser.make_user_admin(user, org)
          end
        end

        it "returns the first judge team even when they admin two judge teams" do
          user.reload
          expect(JudgeTeam.for_judge(user)).to eq(first_judge_team)
          expect(user.administered_teams.length).to eq(2)
        end
      end
    end

    context "a judge team with attorneys on it" do
      let(:judge) { Judge.new(create(:user)) }
      let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
      let(:attorneys) { create_list(:user, 5) }

      before do
        attorneys.each do |u|
          judge_team.add_user(u)
        end
      end

      it_behaves_like "has the judge and attorneys"
    end
  end

  describe "feature judge_admin_scm activated" do
    before { FeatureToggle.enable!(:judge_admin_scm) }
    after { FeatureToggle.disable!(:judge_admin_scm) }

    describe ".create_for_judge" do
      subject { JudgeTeam.create_for_judge(judge) }

      context "when user is not an admin of an existing JudgeTeam" do
        it_behaves_like "successful judge team creation"
      end

      context "when user is already an admin for a JudgeTeam" do
        before { JudgeTeam.create_for_judge(judge) }

        it_behaves_like "judge team already exists"
      end
    end

    describe ".for_judge" do
      context "when user is admin of a non-JudgeTeam organization" do
        let(:judge) { create(:user) }
        let(:user) { create(:user) }
        before { OrganizationsUser.make_user_admin(user, create(:organization)) }

        it "returns nil, indicating user is not the Judge of this team" do
          expect(JudgeTeam.for_judge(user)).to eq(nil)
        end
      end

      context "when user is a non-admin member of JudgeTeam" do
        let(:judge) { create(:user) }
        let(:user) { create(:user) }
        let!(:judge_team) { create(:judge_team) }
        before { populate_judge_team_for_testing(judge_team, judge, [create(:user), user]) }

        it "returns nil" do
          expect(JudgeTeam.for_judge(user)).to eq(nil)
        end
      end

      context "when user is admin of JudgeTeam" do
        let(:judge) { create(:user) }
        let(:user) { create(:user) }
        let!(:judge_team) { create(:judge_team) }
        before { populate_judge_team_for_testing(judge_team, judge, [create(:user), user]) }

        it "returns the judge team" do
          judge.reload
          expect(JudgeTeam.for_judge(judge)).to eq(judge_team)
        end
      end
    end

    context "a judge team with attorneys on it" do
      let(:judge) { Judge.new(create(:user)) }
      let!(:judge_team) { create(:judge_team) }
      let(:attorneys) { create_list(:user, 5) }

      before do
        populate_judge_team_for_testing(judge_team, judge.user, attorneys)
      end
      it_behaves_like "has the judge and attorneys"
    end
  end

  describe ".can_receive_task?" do
    it "returns false because judge teams should not have tasks assigned to them" do
      expect(JudgeTeam.create_for_judge(judge).can_receive_task?(nil)).to eq(false)
    end
  end

  describe "when a user is added to the JudgeTeam" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:attorney) { create(:user) }

    subject { judge_team.add_user(attorney) }

    it "adds an associated non-admin user record for the newly added user" do
      # Before we add the user to the judge team, the only member of the judge team should be the judge.
      expect(judge_team.users.count).to eq(1)
      expect(judge_team.users.first).to eq(judge)

      expect { subject }.to_not raise_error

      expect(judge_team.users.count).to eq(2)
      expect(judge_team.users.first).to eq(judge)
      expect(judge_team.users.second).to eq(attorney)

      expect(attorney.organizations_users.length).to eq(1)
      expect(attorney.organizations_users.first.organization).to eq(judge_team)
    end
  end

  describe ".admin" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }

    context "when the user is the judge" do
      it "judge is the admin" do
        expect(judge_team.admin).to eq(judge)
      end
    end

    context "when the user is an attorney" do
      let(:attorney) { create(:user) }
      before { judge_team.add_user(attorney) }

      it "judge is still the admin" do
        expect(judge_team.admin).not_to eq(attorney)
      end
    end
  end

  private

  # Create a JudgeTeam with an admin and several non-admins (acting as decision-drafting attorneys).
  #
  # Method expects an empty judge team, the user you want to be admin,
  # and an array of non-admin users.
  def populate_judge_team_for_testing(judge_team, judge_user, attorneys)
    judge_team.users << judge_user
    attorneys.each do |u|
      judge_team.users << u
    end
    judge_orguser = OrganizationsUser.existing_record(judge_user, judge_team)
    judge_orguser.update!(admin: true)
  end
end
