# frozen_string_literal: true

describe DvcTeam, :postgres do
  let(:dvc) { create(:user) }
  let(:dvc_team) { DvcTeam.create_for_dvc(dvc) }

  describe ".create_for_dvc" do
    subject { DvcTeam.create_for_dvc(dvc) }

    context "when user is not already an admin of an existing DvcTeam" do
      it "creates a new organization and makes the user an admin of that group" do
        expect(DvcTeam.count).to eq(0)

        expect { subject }.to_not raise_error
        dvc.reload

        expect(DvcTeam.count).to eq(1)
        expect(DvcTeam.first.dvc).to eq(dvc)
        expect(DvcTeam.first.admin).to eq(dvc)
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

      it "returns nil" do
        expect(DvcTeam.for_dvc(user)).to eq(nil)
      end
    end

    context "when dvc user is admin of DvcTeam" do
      let!(:dvc_team) { DvcTeam.create_for_dvc(dvc) }

      it "returns the DvcTeam for the dvc user" do
        expect(DvcTeam.for_dvc(dvc)).to eq(dvc_team)
      end
    end

    context "when user is non-admin member of DvcTeam" do
      before { dvc_team.add_user(user) }

      it "returns nil" do
        expect(DvcTeam.for_dvc(user)).to eq(nil)
      end
    end
  end

  context "a DvcTeam with judges as (non-admin) members" do
    let(:judges) { create_list(:user, 5) }

    before do
      judges.each { |u| dvc_team.add_user(u) }
    end

    it "returns the team dvc and the team judges" do
      expect(dvc_team.users.count).to eq(6)
      expect(dvc_team.judges).to match_array judges
      expect(dvc.organizations_users.length).to eq(1)
      expect(dvc.organizations_users.first.organization).to eq(dvc_team)
    end
  end

  describe ".can_receive_task?" do
    it "returns false because DVC teams should not have tasks assigned to them" do
      expect(dvc_team.can_receive_task?(nil)).to eq(false)
    end
  end
end
