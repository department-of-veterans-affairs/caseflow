# frozen_string_literal: true

RSpec.describe Api::ExternalProxyController, type: :controller do
  fdescribe "FeatureToggle for :external_api_released" do
    controller do
      before_action :is_api_released?

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
        expect{parsed_response = response.body}.to_not raise(JSON::ParserError)
        expect(parsed_response).to eq 'meow'
      end
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
