# frozen_string_literal: true

describe Organizations::UsersController, :postgres, type: :controller do
  describe "GET /organizations/:business_line/users" do
    subject { get :index, params: { organization_url: non_comp_org.url }, format: :json }

    let(:non_admin_user) do
      User.authenticate!(roles: ["VSO"])
    end

    let(:admin_user) do
      User.authenticate!(roles: ["Admin Intake"])
    end

    let(:non_comp_org) { create(:business_line, name: "National Cemetery Administration", url: "nca") }

    context "non-admin user" do
      before { User.stub = non_admin_user }

      it "redirects to /unauthorized" do
        subject

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "admin user" do
      render_views

      before { User.stub = admin_user }

      let(:user) { create(:user) }

      before do
        non_comp_org.add_user(user)
      end

      it "returns 200 and users in org" do
        subject

        expect(response.status).to eq 200
        expect(response.body).to match(user.username)
      end

      it "includes admin field for users in organization" do
        subject

        resp = JSON.parse(response.body)
        org_user = resp["organization_users"]["data"].first
        expect(org_user["attributes"]["css_id"]).to eq(user.css_id)
        expect(org_user["attributes"]["admin"]).to eq(false)
      end
    end
  end

  describe "PATCH /organizations/:org_url/users/:user_id" do
    subject { patch(:update, params: params, as: :json) }
    context "when the param is admin" do
      let(:org) { create(:organization) }
      let(:user) { create(:user) }
      let(:admin) do
        create(:user).tap do |u|
          OrganizationsUser.make_user_admin(u, org)
        end
      end

      before do
        User.authenticate!(user: admin)
      end

      context "when the admin field is not included as a request parameter" do
        let(:params) { { organization_url: org.url, id: user.id } }

        before { org.add_user(user) }

        it "returns the user but does not alter the user in any way" do
          subject

          resp = JSON.parse(response.body)
          modified_user = resp["users"]["data"].first
          expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
          expect(modified_user["attributes"]["admin"]).to eq(false)

          expect(org.admins.count).to eq(1)
          expect(org.non_admins.count).to eq(1)
        end
      end

      context "when admin field is included as a request parameter" do
        let(:params) { { organization_url: org.url, id: user.id, admin: admin_flag } }

        context "when the admin flag is true" do
          let(:admin_flag) { true }

          context "when the target user is not a member of the organization" do
            it "adds the user to the organization and makes them an admin" do
              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(0)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(true)

              expect(org.admins.count).to eq(2)
              expect(org.non_admins.count).to eq(0)
            end
          end

          context "when the target user is a non-admin in the organization" do
            before { org.add_user(user) }

            it "makes the target user an admin of the team" do
              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(1)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(true)

              expect(org.admins.count).to eq(2)
              expect(org.non_admins.count).to eq(0)
            end
          end

          context "when the target user is already an admin in the organization" do
            before { OrganizationsUser.make_user_admin(user, org) }

            it "does not change the target user admin rights" do
              expect(org.admins.count).to eq(2)
              expect(org.non_admins.count).to eq(0)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(true)

              expect(org.admins.count).to eq(2)
              expect(org.non_admins.count).to eq(0)
            end
          end
        end

        context "when the admin flag is false" do
          let(:admin_flag) { false }

          context "when the target user is not a member of the organization" do
            it "does not change the admin rights of the user or their membership in the organization" do
              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(0)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(false)

              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(0)
            end
          end

          context "when the target user is a non-admin in the organization" do
            before { org.add_user(user) }

            it "does not change the target user admin rights" do
              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(1)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(false)

              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(1)
            end
          end

          context "when the target user is already an admin in the organization" do
            before { OrganizationsUser.make_user_admin(user, org) }

            it "removes admin rights from the target user" do
              expect(org.admins.count).to eq(2)
              expect(org.non_admins.count).to eq(0)

              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
              expect(modified_user["attributes"]["admin"]).to eq(false)

              expect(org.admins.count).to eq(1)
              expect(org.non_admins.count).to eq(1)
            end
          end
        end

        context "when the admin flag is something other than true or false" do
          let(:admin_flag) { "neither true nor false" }

          before { OrganizationsUser.make_user_admin(user, org) }

          it "removes admin rights from the target user" do
            expect(org.admins.count).to eq(2)
            expect(org.non_admins.count).to eq(0)

            subject

            resp = JSON.parse(response.body)
            modified_user = resp["users"]["data"].first
            expect(modified_user["attributes"]["css_id"]).to eq(user.css_id)
            expect(modified_user["attributes"]["admin"]).to eq(false)

            expect(org.admins.count).to eq(1)
            expect(org.non_admins.count).to eq(1)
          end
        end
      end
    end

    context "when the param is attorney" do
      before { FeatureToggle.enable!(:judge_admin_scm) }
      after { FeatureToggle.disable!(:judge_admin_scm) }
      let(:judge) { create(:user) }
      let(:judge_team) { JudgeTeam.create_for_judge(judge) }
      let(:judge_team_member) { create(:user) }
      let!(:judge_team_member_orguser) { judge_team.add_user(judge_team_member) }

      before do
        User.authenticate!(user: judge)
      end

      context "when the attorney field is not included as a request parameter" do
        let(:params) { { organization_url: judge_team.url, id: judge_team_member.id } }

        it "returns the user but does not alter the user in any way" do
          subject

          resp = JSON.parse(response.body)
          modified_user = resp["users"]["data"].first
          expect(modified_user["attributes"]["css_id"]).to eq(judge_team_member.css_id)
          expect(modified_user["attributes"]["attorney"]).to eq(true)

          expect(judge_team.judge_team_roles.count).to eq(2)
        end
      end

      context "when attorney field is included as a request parameter" do
        let(:params) { { organization_url: judge_team.url, id: judge_team_member.id, attorney: attorney_flag } }

        context "when the attorney flag is true" do
          let(:attorney_flag) { true }

          context "when the target user is an attorney" do
            it "does nothing" do
              expect(judge_team_member_orguser.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
              expect(judge_team.judge_team_roles.count).to eq(2)
              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(judge_team_member.css_id)
              expect(modified_user["attributes"]["attorney"]).to eq(true)

              expect(judge_team.judge_team_roles.count).to eq(2)
            end
          end

          context "when the target user is not an attorney" do
            # make the attorney a non drafting team member
            before { OrganizationsUser.disable_decision_drafting(judge_team_member, judge_team) }

            it "gives the user the attorney role" do
              expect(judge_team_member_orguser.reload.judge_team_role.type).to eq(nil)
              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(judge_team_member.css_id)
              expect(modified_user["attributes"]["attorney"]).to eq(true)

              expect(judge_team.judge_team_roles.count).to eq(2)
            end
          end
        end

        context "when the attorney flag is false" do
          let(:attorney_flag) { false }

          context "when the target user is not an attorney" do
            # make the attorney a non drafting team member
            before { OrganizationsUser.disable_decision_drafting(judge_team_member, judge_team) }

            it "does nothing" do
              expect(judge_team_member_orguser.reload.judge_team_role.type).to eq(nil)
              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(judge_team_member.css_id)
              expect(modified_user["attributes"]["attorney"]).to eq(false)

              expect(judge_team.judge_team_roles.count).to eq(2)
            end
          end

          context "when the target user is an attorney" do
            it "removes the attorney role from the user" do
              expect(judge_team_member_orguser.judge_team_role.type).to eq(DecisionDraftingAttorney.name)
              subject

              resp = JSON.parse(response.body)
              modified_user = resp["users"]["data"].first
              expect(modified_user["attributes"]["css_id"]).to eq(judge_team_member.css_id)
              expect(modified_user["attributes"]["attorney"]).to eq(false)

              expect(judge_team.judge_team_roles.count).to eq(2)
            end
          end
        end
      end
    end
  end

  describe "DELETE /organizations/:org_url/users/:user_id", skip: "Flake" do
    subject { post(:destroy, params: params, as: :json) }

    let!(:params) { { organization_url: org.url, id: user.id } }

    let(:org) { create(:judge_team, :has_judge_team_lead_as_admin) }
    let(:user) { org.judge }
    let(:admin) do
      create(:user).tap do |u|
        OrganizationsUser.make_user_admin(u, org)
      end
    end

    before do
      User.stub = admin
    end

    context "when user is the judge in the organization" do
      it "returns an error" do
        subject

        expect(response.status).to eq 403
        resp = JSON.parse(response.body)
        expect(resp["errors"].first["detail"]).to eq COPY::JUDGE_TEAM_REMOVE_JUDGE_ERROR
      end
    end
  end
end
