# frozen_string_literal: true

RSpec.describe Api::ExternalProxyController, type: :controller do
  describe "#api_released used in before_action" do
    controller do
      before_action :api_released?

      def index
        render json: { meta: { text: "This is just a test action." } }
      end
    end

    describe "when not enabled" do
      it "should return a 501 response" do
        get :index
        expect(response).to have_http_status(:not_implemented)
      end
      it "should have a jsonapi error response" do
        get :index
        expect { JSON.parse(response.body) }.to_not raise_error
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["errors"]).to be_a Array
        expect(parsed_response["errors"].first).to include("status", "title", "detail")
      end
    end

    describe "when enabled" do
      it "should return a 200 response" do
        FeatureToggle.enable!(:api_v3)
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
