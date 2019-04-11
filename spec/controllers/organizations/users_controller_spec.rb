# frozen_string_literal: true

describe Organizations::UsersController, type: :controller do
  let(:non_admin_user) do
    User.authenticate!(roles: ["VSO"])
  end

  let(:admin_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  describe "GET /organizations/:business_line/users" do
    subject { get :index, params: { organization_url: non_comp_org.url }, format: :json }

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
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
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
end
