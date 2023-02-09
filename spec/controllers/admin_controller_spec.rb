# frozen_string_literal: true

RSpec.describe AdminController, :all_dbs, type: :controller do
  describe "GET /admin" do
    context "sys_admin_page enabled" do
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

      context "when user hits the veteran extract route with veterans" do
        let(:admin_user) { create(:user) }
        let!(:user) { User.authenticate!(roles: ["System Admin"]) }

        it "returns a 200 response" do
          allow(controller).to receive(:verify_authentication).and_return(true)

          post :veteran_extract
          expect(response).to be_successful
        end

        it "returns a 200 response with feature toggle enabled" do
          FeatureToggle.enable!(:vet_extract_timestamp)
          allow(controller).to receive(:verify_authentication).and_return(true)

          post :veteran_extract
          expect(response).to be_successful
        end
      end

      context "when user hits the veteran extract route with veterans, using pipe delimited" do
        let(:admin_user) { create(:user) }
        let!(:user) { User.authenticate!(roles: ["System Admin"]) }
        FeatureToggle.enable!(:vet_extract_pipe_delimited)

        it "returns a 200 response" do
          allow(controller).to receive(:verify_authentication).and_return(true)

          post :veteran_extract
          expect(response).to be_successful
        end
      end

      context "when user hits the veteran extract route with no veterans" do
        let(:admin_user) { create(:user) }
        let!(:user) { User.authenticate!(roles: ["System Admin"]) }

        it "returns a 200 response" do
          allow(controller).to receive(:verify_authentication).and_return(true)
          allow(controller).to receive(:retrieve_veterans).and_return([])

          post :veteran_extract
          expect(response).to be_successful
        end
      end

      context "when user hits the veteran extract route error occurs" do
        let(:admin_user) { create(:user) }
        let!(:user) { User.authenticate!(roles: ["System Admin"]) }

        it "error occurred" do
          allow(controller).to receive(:verify_authentication).and_return(true)
          allow_any_instance_of(SystemAdminEvent).to receive(:update!).and_raise(StandardError)

          expect { post :veteran_extract }.to raise_error(StandardError)
        end
      end
    end

    context "sys_admin_page disabled" do
      before do
        FeatureToggle.enable!(:test_facols)
      end

      context "when user has access to admin" do
        let(:admin_user) { create(:user) }
        let!(:user) { User.authenticate!(roles: ["System Admin"]) }

        it "should return 302" do
          get :index
          expect(response.status).to eq 302
        end

        it "should call the verify_access method" do
          expect_any_instance_of(AdminController).to receive(:verify_access).exactly(1).times
          get :index
        end
      end
    end
  end
end
