require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewsController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }

    context "with a valid token" do
      it "returns success response" do
        request.headers["Authorization"] = api_key.key_string
        post :decision_review_created
        expect(response).to have_http_status(:created)
      end
    end

    context "with an invalid token" do
      it "returns unauthorized response" do
        request.headers["Authorization"] = "invalid_token"
        post :decision_review_created
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without a token" do
      it "returns unauthorized response" do
        # Omitting Authorization header to simulate missing token
        post :decision_review_created
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
