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

  describe ".enable_decision_drafting" do
    before { FeatureToggle.enable!(:judge_admin_scm) }
    after { FeatureToggle.disable!(:judge_admin_scm) }
    let(:judge) { create(:user) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:judge_team_org_user) { judge_team.add_user(user) }

    context "when a user is a judge" do
      it "fails" do
        expect { OrganizationsUser.enable_decision_drafting(judge, judge_team) }
          .to raise_error(Caseflow::Error::ActionForbiddenError).with_message(COPY::JUDGE_TEAM_ATTORNEY_RIGHTS_ERROR)
      end
    end

    context "when a user is an attorney" do
      it "does nothing" do
        expect(judge_team_org_user.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
        OrganizationsUser.enable_decision_drafting(user, judge_team)
        expect(judge_team_org_user.reload.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
      end
    end

    context "when a user is not an attorney" do
      before { judge_team_org_user.judge_team_role.update!(type: nil) }
      it "gives the user the attorney role" do
        OrganizationsUser.enable_decision_drafting(user, judge_team)
        expect(judge_team_org_user.reload.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
      end
    end
  end

  describe ".disable_decision_drafting" do
    before { FeatureToggle.enable!(:judge_admin_scm) }
    after { FeatureToggle.disable!(:judge_admin_scm) }
    let(:judge) { create(:user) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:judge_team_org_user) { judge_team.add_user(user) }

    context "when a user is a judge" do
      it "fails" do
        expect { OrganizationsUser.enable_decision_drafting(judge, judge_team) }
          .to raise_error(Caseflow::Error::ActionForbiddenError).with_message(COPY::JUDGE_TEAM_ATTORNEY_RIGHTS_ERROR)
      end
    end

    context "when a user is not an attorney" do
      before { judge_team_org_user.judge_team_role.update!(type: nil) }
      it "does nothing" do
        OrganizationsUser.disable_decision_drafting(user, judge_team)
        expect(judge_team_org_user.reload.judge_team_role.type).to eq(nil)
      end
    end

    context "when a user is an attorney" do
      it "removes the attorney role" do
        expect(judge_team_org_user.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
        OrganizationsUser.disable_decision_drafting(user, judge_team)
        expect(judge_team_org_user.reload.judge_team_role.type).to eq(nil)
      end
    end
  end
end
