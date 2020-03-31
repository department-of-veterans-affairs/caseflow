# frozen_string_literal: true

describe ApplicationController, type: :controller do
  let(:user) { build(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "#feedback" do
    def all_users_can_access_feedback
      get :feedback

      expect(response.status).to eq 200
    end

    it "allows users to see feedback page" do
      all_users_can_access_feedback
    end

    context "user is part of VSO" do
      before do
        allow(user).to receive(:vso_employee?) { true }
      end

      it "allows VSO user to see feedback page" do
        all_users_can_access_feedback
      end
    end
  end

  describe "no cache headers" do
    controller(ApplicationController) do
      def index
        render json: { hello: "world" }, status: :ok
      end
    end

    context "when toggle not set" do
      it "does not set Cache-Control" do
        get :index

        expect(response.headers["Cache-Control"]).to be_nil
      end
    end

    context "when toggle set" do
      before do
        FeatureToggle.enable!(:set_no_cache_headers)
      end

      after do
        FeatureToggle.disable!(:set_no_cache_headers)
      end

      it "sets Cache-Control etc" do
        get :index

        expect(response.headers["Cache-Control"]).to eq "no-cache, no-store"
      end
    end
  end
end
