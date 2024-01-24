# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }

    context "with a valid token" do
      it "returns success response" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
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

  describe "POST #decision_review_created_error" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "Appeals-Consumer") }
    context "with an Authorized Token" do
      it "renders message Error Creating Decision Review and returns a method not allowed status" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error
        expect(response).to have_http_status(:method_not_allowed)
        expect(JSON.parse(response.body)["message"]).to eq("Error Creating Decision Review")
      end
    end
    context "with an invalid Token" do
      it "returns unauthorized response" do
        request.headers["Authorization"] = "unAuthToken"
        post :decision_review_created_error
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "with no token" do
      it "returns unauthorized response" do
        post :decision_review_created_error
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
