# frozen_string_literal: true

RSpec.fdescribe Api::ExternalProxyController, type: :controller do
  describe "FeatureToggle for :external_api_released" do
    controller do
      before_action :is_api_released?

      def index
        render json: { meta: { text: "This is just a test action." } }
      end
    end

    describe "when not enabled" do
      it "should return a 501 response"
      it "should have a jsonapi error response"
    end

    describe "when enabled" do
      it "should return a 200 response" do
        FeatureToggle.enable!(:external_api_released)
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
