# frozen_string_literal: true

RSpec.describe AdminController, :all_dbs, type: :controller do
  describe "GET /admin" do
    before do
      FeatureToggle.enable!(:sys_admin_page)
      FeatureToggle.enable!(:test_facols)

      2.times do
        create(:correspondent,
          snamef: "Bobby",
          snamemi: "F",
          snamel: "Veteran",
          stadtime: Time.zone.now)
      end
    end


    context "when user has access to admin" do
      let(:admin_user) { create(:user) }
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }

      it "should return the admin landing page" do
        get :index
        expect(response.status).to eq 200
      end

      it "should call the verify_access method" do
        expect_any_instance_of(AdminController).to receive(:verify_access).exactly(1).times
        get :index
      end
    end

    context "when user hits the veteran extract route" do
      let(:admin_user) { create(:user) }
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }

      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        post :veteran_extract
        expect(response).to be_successful
      end
    end
  end
end
