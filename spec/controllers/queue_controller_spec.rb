RSpec.describe QueueController, type: :controller do
  describe "GET /queue" do
    context "when user has access to queue" do
      let(:attorney_user) { FactoryBot.create(:user) }
      let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

      before { User.authenticate!(user: attorney_user) }

      it "should return the queue landing page" do
        get :index
        expect(response.status).to eq 200
      end
    end

    context "when user is a VSO employee" do
      let(:vso_user) { FactoryBot.create(:user) }

      let(:url) { "american-legion" }
      let(:feature) { "org_queue_american_legion" }
      let!(:vso) { Vso.create(url: url, feature: feature) }

      before do
        Functions.grant!("VSO", users: [vso_user.css_id])
        FeatureToggle.enable!(feature.to_sym, users: [vso_user.css_id])
        User.authenticate!(user: vso_user)
      end

      it "should redirect to VSO's organizational queue" do
        get :index
        expect(response.status).to eq 302
        expect(response.redirect_url).to match(/#{vso.path}$/)
      end
    end
  end
end
