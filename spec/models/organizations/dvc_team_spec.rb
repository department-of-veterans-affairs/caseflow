# frozen_string_literal: true

describe DvcTeam, :postgres do
  let(:dvc) { create(:user) }

  describe ".create_for_dvc" do
    subject { DvcTeam.create_for_dvc(dvc) }

    context "when user is not already an admin of an existing DvcTeam" do
      it "should create a new organization and make the user an admin of that group" do
        expect(DvcTeam.count).to eq(0)

        expect { subject }.to_not raise_error
        dvc.reload

        expect(DvcTeam.count).to eq(1)
        expect(DvcTeam.first.admins.first).to eq(dvc)
      end
    end

    context "when a DvcTeam already exists for this user" do
      before { DvcTeam.create_for_dvc(dvc) }

      it "raises an error and fails to create the new DvcTeam" do
        dvc.reload
        expect { subject }.to raise_error(Caseflow::Error::DuplicateDvcTeam)
      end
    end
  end

  describe ".for_dvc" do
    let(:user) { create(:user) }

    context "when user is admin of a non-DvcTeam organization" do
      before { OrganizationsUser.make_user_admin(user, create(:organization)) }

      it "should return nil" do
        expect(DvcTeam.for_dvc(user)).to eq(nil)
      end
    end

    context "when user is admin of DvcTeam" do
      let!(:dvc_team) { DvcTeam.create_for_dvc(user) }

      it "should return dvc team" do
        user.reload
        expect(DvcTeam.for_dvc(user)).to eq(dvc_team)
      end
    end

    context "when user is member of DvcTeam" do
      let!(:dvc_team) { DvcTeam.create_for_dvc(dvc) }
      before { dvc_team.add_user(user) }

      it "should return nil" do
        expect(DvcTeam.for_dvc(user)).to eq(nil)
      end
    end

    # Limitation of the current approach is that users are effectively limited to being the admin of
    # a single DvcTeam.
    context "when user is admin of multiple DvcTeams" do
      let!(:first_dvc_team) { DvcTeam.create_for_dvc(user) }
      let!(:second_dvc_team) do
        DvcTeam.create!(name: "#{user.css_id}_2", url: "#{user.css_id.downcase}_2").tap do |org|
          OrganizationsUser.make_user_admin(user, org)
        end
      end

      it "should return first dvc team even when they admin two dvc teams" do
        user.reload
        expect(DvcTeam.for_dvc(user)).to eq(first_dvc_team)
        expect(user.administered_teams.length).to eq(2)
      end
    end
  end

  context "a dvc team with judges on it" do
    let(:dvc) { create(:user) }
    let!(:dvc_team) { DvcTeam.create_for_dvc(dvc) }
    let(:judges) { create_list(:user, 5) }

    before do
      judges.each do |u|
        dvc_team.add_user(u)
      end
    end

    it "returns the team dvc and the team judges" do
      expect(dvc_team.dvc).to eq dvc
      expect(dvc_team.judges).to match_array judges
    end
  end

  describe ".can_receive_task?" do
    let(:dvc) { create(:user) }
    let!(:dvc_team) { DvcTeam.create_for_dvc(dvc) }
    it "should return false because dvc teams should not have tasks assigned to them in the web UI" do
      expect(dvc_team.can_receive_task?(nil)).to eq(false)
    end
  end

  describe "when a user is added to the DvcTeam" do
    let(:dvc_team) { DvcTeam.create_for_dvc(dvc) }
    let(:judge) { create(:user) }

    subject { dvc_team.add_user(judge) }

    it "adds an associated DecisionDraftingAttorney record for the newly added user" do
      # Before we add the user to the dvc team, the only member of the dvc team should be the dvc.
      expect(dvc_team.users.count).to eq(1)
      expect(dvc_team.users.first).to eq(dvc)

      expect { subject }.to_not raise_error

      expect(dvc_team.users.count).to eq(2)
      expect(dvc_team.users.first).to eq(dvc)
      expect(dvc_team.users.second).to eq(judge)

      # Make sure that the judge user is on the dvc team.
      expect(judge.organizations_users.length).to eq(1)
      expect(judge.organizations_users.first.organization).to eq(dvc_team)
    end
  end
end
