require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewsController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }

    context "with a valid token" do
      it "returns success response" do
        allow(controller).to receive(:authenticate_microservice!).and_return(true)
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
        request.headers["Authorization"] = ""
        post :decision_review_created
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
