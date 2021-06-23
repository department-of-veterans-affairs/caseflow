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

    let(:bva_admin_user) do
      create(:user).tap { |bva_admin| Bva.singleton.add_user(bva_admin) }
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

    shared_examples "can view org" do
      render_views

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

    context "admin user" do
      before { User.stub = admin_user }

      it_behaves_like "can view org"
    end

    context "bva admin user" do
      before { User.stub = bva_admin_user }

      it_behaves_like "can view org"
    end
  end

  describe "GET /organizations/:org_url/users" do
    subject { get :index, params: { organization_url: dvc_team.url }, format: :json }

    context "DvcTeam admin user" do
      let(:user) { create(:user) }
      let(:dvc_team) { DvcTeam.create_for_dvc(user) }

      before do
        User.authenticate!(user: user)
      end

      it "includes admin field for users in organization" do
        subject
        resp = JSON.parse(response.body)
        org_user = resp["organization_users"]["data"].first
        expect(org_user["attributes"]["css_id"]).to eq(user.css_id)
        expect(org_user["attributes"]["admin"]).to eq(true)
        expect(org_user["attributes"]["dvc"]).to eq(true)
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
  end

  describe "DELETE /organizations/:org_url/users/:user_id" do
    subject { post(:destroy, params: params, as: :json) }

    let!(:params) { { organization_url: org.url, id: user.id } }

    let(:org) { create(:judge_team, :has_judge_team_lead_as_admin) }
    let!(:user) do
      create(:user).tap do |user|
        org.add_user(user)
      end
    end

    let(:bva_admin_user) do
      create(:user).tap { |bva_admin| Bva.singleton.add_user(bva_admin) }
    end

    before { User.stub = bva_admin_user }

    context "when user is a non-judge in the organization" do
      it "removes user from organization" do
        expect(OrganizationsUser.where(organization: org).count).to eq(2)
        subject
        resp = JSON.parse(response.body)
        # response has the removed user
        expect(resp["users"]["data"].first["attributes"]["css_id"]).to eq user.css_id

        expect(OrganizationsUser.where(organization: org).count).to eq(1)
        expect(org.admins.count).to eq(1)
        expect(org.non_admins.count).to eq(0)
      end
    end

    context "when user is the judge in the organization", skip: "Flake" do
      it "returns an error" do
        subject

        expect(response.status).to eq 403
        resp = JSON.parse(response.body)
        expect(resp["errors"].first["detail"]).to eq COPY::JUDGE_TEAM_REMOVE_JUDGE_ERROR
      end
    end
  end
end
