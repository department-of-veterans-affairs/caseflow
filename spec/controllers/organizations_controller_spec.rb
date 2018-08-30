RSpec.describe OrganizationsController, type: :controller do
  describe "GET /organizations" do
    context "when user is logged in" do
      let(:user) { FactoryBot.create(:user) }
      before { User.authenticate!(user: user) }

      context "when there are Organizations in the table" do
        let(:org_count) { 8 }
        before { FactoryBot.create_list(:organization, org_count) }

        it "should return a list of all Organizations" do
          get :index
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["organizations"].length).to eq(org_count)
        end
      end

      context "when there are Organizations and Organization subclasses in the table" do
        let(:org_count) { 5 }
        before do
          FactoryBot.create_list(:organization, org_count)
          FactoryBot.create_list(:vso, 2)
          FactoryBot.create_list(:bva, 1)
        end

        it "should return only a list of the Organizations" do
          get :index
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["organizations"].length).to eq(org_count)
        end
      end
    end
  end

  describe "GET /organizations/:url/members" do
    context "when user is not a member of the organization" do
      let(:user) { FactoryBot.create(:user) }
      let(:org) { FactoryBot.create(:organization) }
      before { User.authenticate!(user: user) }

      it "should redirect to /unauthorized" do
        get :members, params: { url: org.url }
        expect(response.status).to eq(302)
        expect(response.redirect_url).to match(/unauthorized$/)
      end
    end

    context "when user is a member of the organization" do
      let(:member_cnt) { 12 }
      let(:user) { FactoryBot.create(:user) }
      let(:other_members) { FactoryBot.create_list(:user, member_cnt - 1) }
      let(:org) { FactoryBot.create(:organization) }
      before do
        [other_members, user].flatten.each do |u|
          FeatureToggle.enable!(org.feature.to_sym, users: [u.css_id])
        end
        User.authenticate!(user: user)
      end

      it "should return a list of the members" do
        get :members, params: { url: org.url }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["members"].length).to eq(member_cnt)
      end

      context "when we access the page by organization ID instead of custom URL slug" do
        it "should return a list of the members" do
          get :members, params: { url: org.id }
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["members"].length).to eq(member_cnt)
        end
      end
    end
  end
end
