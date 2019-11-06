# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe JudgeTeam, :postgres do
  let(:judge) { create(:user) }

  describe ".create_for_judge" do
    subject { JudgeTeam.create_for_judge(judge) }

    context "when user is not already an admin of an existing JudgeTeam" do
      it "should create a new organization and make the user an admin of that group" do
        expect(judge.organizations.length).to eq(0)

        expect { subject }.to_not raise_error
        judge.reload

        expect(judge.organizations.length).to eq(1)
        expect(judge.administered_teams.length).to eq(1)
        expect(judge.administered_teams.first.class).to eq(JudgeTeam)
        expect(judge.administered_teams.first.url).to eq(judge.css_id.downcase.parameterize.dasherize)
      end

      it "creates association with a JudgeTeamLead role with the judge" do
        # Confirm there are no JudgeTeamLead entities associated with this judge.
        expect(JudgeTeamLead.count).to eq(0)

        judge_team = subject

        # Find the association we should have created.
        org_user = OrganizationsUser.find_by(organization: judge_team, user: judge)

        # Make sure there is a JudgeTeamLead connected to it.
        expect(org_user.judge_team_role).to be_a(JudgeTeamLead)
      end
    end

    context "when a JudgeTeam already exists for this user" do
      before { JudgeTeam.create_for_judge(judge) }

      it "raises an error and fails to create the new JudgeTeam" do
        judge.reload
        expect { subject }.to raise_error(Caseflow::Error::DuplicateJudgeTeam)
      end
    end
  end

  describe ".for_judge" do
    let(:user) { create(:user) }

    context "when user is admin of a non-JudgeTeam organization" do
      before { OrganizationsUser.make_user_admin(user, create(:organization)) }

      it "should return nil" do
        expect(JudgeTeam.for_judge(user)).to eq(nil)
      end
    end

    context "when user is member of JudgeTeam" do
      let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
      before { judge_team.add_user(user) }

      it "should return nil" do
        expect(JudgeTeam.for_judge(user)).to eq(nil)
      end
    end

    context "when user is admin of JudgeTeam" do
      let!(:judge_team) { JudgeTeam.create_for_judge(user) }

      it "should return judge team" do
        user.reload
        expect(JudgeTeam.for_judge(user)).to eq(judge_team)
      end
    end

    # Limitation of the current approach is that users are effectively limited to being the admin of a single JudgeTeam.
    context "when user is admin of multiple JudgeTeams" do
      let!(:first_judge_team) { JudgeTeam.create_for_judge(user) }
      let!(:second_judge_team) do
        JudgeTeam.create!(name: "#{user.css_id}_2", url: "#{user.css_id.downcase}_2").tap do |org|
          OrganizationsUser.make_user_admin(user, org)
        end
      end

      it "should return first judge team even when they admin two judge teams" do
        user.reload
        expect(JudgeTeam.for_judge(user)).to eq(first_judge_team)
        expect(user.administered_teams.length).to eq(2)
      end
    end
  end

  context "a judge team with attorneys on it" do
    let(:user) { create(:user) }
    let(:judge) { Judge.new(user) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:attorneys) { create_list(:user, 5) }

    before do
      attorneys.each do |u|
        judge_team.add_user(u)
      end
    end

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

  describe ".can_receive_task?" do
    it "should return false because judge teams should not have tasks assigned to them in the web UI" do
      expect(JudgeTeam.create_for_judge(judge).can_receive_task?(nil)).to eq(false)
    end
  end

  describe "when a user is added to the JudgeTeam" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:attorney) { create(:user) }

    subject { judge_team.add_user(attorney) }

    it "adds an associated DecisionDraftingAttorney record for the newly added user" do
      # Before we add the user to the judge team, the only member of the judge team should be the judge.
      expect(judge_team.users.count).to eq(1)
      expect(judge_team.users.first).to eq(judge)

      expect { subject }.to_not raise_error

      expect(judge_team.users.count).to eq(2)
      expect(judge_team.users.first).to eq(judge)
      expect(judge_team.users.second).to eq(attorney)

      # Make sure that the user we just added has the JudgeTeamRole of DecisionDraftingAttorney for the judge team.
      expect(attorney.organizations_users.length).to eq(1)
      expect(attorney.organizations_users.first.judge_team_role).to be_a(DecisionDraftingAttorney)
      expect(attorney.organizations_users.first.organization).to eq(judge_team)
    end
  end
end
