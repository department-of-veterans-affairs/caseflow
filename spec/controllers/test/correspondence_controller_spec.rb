# frozen_string_literal: true

describe Test::CorrespondenceController, :postgres, type: :controller do
  let!(:user) { create(:user) }

  before do
    User.authenticate!(user: user)
  end
  describe "GET #index" do
    context "when user has access" do
      before do
        allow(user).to receive(:admin?).and_return(true)
        allow(controller).to receive(:access_allowed?).and_return(true)
        allow(controller).to receive(:verify_access).and_return(true)
        allow(controller).to receive(:verify_feature_toggle).and_return(true)
      end

      it "renders the index template" do
        get :index
        expect(response.status).to eq 200
      end
    end

    context "when user does not have access" do
      before do
        allow(user).to receive(:admin?).and_return(false)
        allow(controller).to receive(:access_allowed?).and_return(false)
        allow(controller).to receive(:verify_access).and_call_original
      end

      it "redirects to unauthorized path" do
        get :index
        expect(response).to redirect_to("/unauthorized")
      end
    end

    context "when feature toggle is disabled" do
      before do
        allow(user).to receive(:admin?).and_return(true)
        allow(controller).to receive(:access_allowed?).and_return(true)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_queue).and_return(false)
        allow(controller).to receive(:verify_access).and_return(true)
      end

      it "redirects to under construction path" do
        get :index
        expect(response.status).to eq(302)
      end
    end

    context "when feature toggle and user access are disabled" do
      before do
        allow(user).to receive(:admin?).and_return(false)
        allow(controller).to receive(:access_allowed?).and_return(false)
        allow(controller).to receive(:verify_access).and_return(false)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_queue).and_return(false)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_admin).and_return(true)
      end

      it "redirects to unauthorized path" do
        get :index
        expect(response).to redirect_to("/unauthorized")
      end
    end
  end

  describe "private methods" do
    describe "#verify_access" do
      context "when user is an admin" do
        before do
          allow(user).to receive(:admin?).and_return(true)
        end

        it "returns true" do
          expect(controller.send(:verify_access)).to be true
        end
      end
    end

    describe "#bva?" do
      it "checks user access for BVA roles" do
        Bva.singleton.add_user(current_user)
        expect(controller.send(:bva?)).to be true
      end
    end

    describe "#access_allowed?" do
      context "in UAT environment" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
          allow(Rails).to receive(:deploy_env?).with(:demo).and_return(false)
        end

        it "returns true" do
          expect(controller.send(:access_allowed?)).to be true
        end
      end

      context "in demo environment" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(false)
          allow(Rails).to receive(:deploy_env?).with(:demo).and_return(true)
        end

        it "returns true" do
          expect(controller.send(:access_allowed?)).to be true
        end
      end
    end
  end
end
