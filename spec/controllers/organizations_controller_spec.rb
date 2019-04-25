# frozen_string_literal: true

RSpec.describe OrganizationsController, type: :controller do
  describe "GET organization/:organization_id" do
    let(:user) { FactoryBot.create(:user) }
    let(:organization) { FactoryBot.create(:organization) }

    subject { get(:show, params: { url: organization.id }) }

    before { User.authenticate!(user: user) }

    context "when user is a member of the organization" do
      before { OrganizationsUser.add_user_to_organization(user, organization) }

      it "allows us to access the organization's queue page" do
        subject
        expect(response.code).to eq("200")
        # Current page is what we expect
      end
    end

    context "when user is a system admin" do
      before { Functions.grant!("System Admin", users: [user.css_id]) }
      after { Functions.client.del("System Admin") }

      it "allows us to access the organization's queue page" do
        subject
        expect(response.code).to eq("200")
        # Current page is what we expect
      end
    end

    context "when user is not a member of the organization" do
      it "redirects us to the unauthorized screen" do
        subject
        expect(response.code).to eq("302")
        # Current page is unauthorized
      end
    end
  end
end
