# frozen_string_literal: true

describe OrganizationsUser, :postgres do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  describe ".remove_admin_rights_from_user" do
    subject { OrganizationsUser.remove_admin_rights_from_user(user, organization) }

    context "when user is not a member of the organization" do
      it "does not add the user to the organization" do
        expect(subject).to eq(nil)
        expect(organization.users.count).to eq(0)
      end
    end

    context "when user is a member of the organization" do
      before { organization.add_user(user) }

      it "does nothing" do
        expect(subject).to eq(true)
        expect(organization.admins.count).to eq(0)
      end
    end

    context "when user is an admin of the organization but not a judge" do
      before { OrganizationsUser.make_user_admin(user, organization) }

      it "removes admin rights from the user" do
        expect(organization.admins.count).to eq(1)
        expect(subject).to eq(true)
        expect(organization.admins.count).to eq(0)
      end
    end

    context "when user is the admin (judge) of a JudgeTeam" do
      let(:organization) { JudgeTeam.create_for_judge(user) }

      it "does not allow them to be removed" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
          .with_message "Cannot remove adminship from a judge on their team"
      end
    end
  end

  describe ".remove_user_from_organization" do
    subject { OrganizationsUser.remove_user_from_organization(user, organization) }

    context "when the user is not part of the organization" do
      it "it does nothing" do
        expect { subject }.to_not raise_error
      end
    end

    context "when the user is an ordinary user" do
      before { organization.add_user(user) }

      it "removes the user" do
        expect(organization.users.count).to eq(1)
        subject
        expect(organization.users.count).to eq(0)
      end
    end

    context "when the user is a judge in a JudgeTeam" do
      let(:organization) { JudgeTeam.create_for_judge(user) }

      it "does not remove them" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end

  describe "when making organization inactive" do
    subject { organization.inactive! }

    before { organization.add_user(user) }

    it "doesn't list the organization for the user" do
      expect(organization.users.count).to eq(1)
      expect(OrganizationsUser.count).to eq(1)
      subject
      # User is no longer part of the inactive organization
      expect(user.organizations).to_not include organization

      # However, associations queried from the organization are unchanged
      expect(organization.users.count).to eq(1)
      # because record in OrganizationsUser table still exists
      expect(OrganizationsUser.count).to eq(1)
    end
  end

  describe ".make_user_admin" do
    context "when the organization is not a judge team" do
      before { OrganizationsUser.make_user_admin(user, organization) }
      it "makes the user an admin" do
        expect(organization.admins.count).to eq(1)
      end
    end

    context "when the organization is a new judge team" do
      let(:judge_team) { JudgeTeam.create_for_judge(user) }
      it "makes the user an admin" do
        expect(judge_team.admin).to eq(user)
      end
    end

    context "when the organization is a previously created judge team" do
      let(:judge_team) { JudgeTeam.create_for_judge(user) }
      let(:new_team_member) { create(:user) }
      it "does not make the user an admin" do
        expect { OrganizationsUser.make_user_admin(new_team_member, judge_team) }
          .to raise_error(Caseflow::Error::ActionForbiddenError).with_message(COPY::JUDGE_TEAM_ADMIN_ERROR)
      end
    end
  end
end
