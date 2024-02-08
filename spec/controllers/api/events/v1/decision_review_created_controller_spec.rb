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
    let!(:appeals_consumer_paylod) { { "event_id": 3333, "errored_claim_id": 1345, "error": "this was an error" } }
    context "with an Authorized Token" do
      it "renders message Error Creating Decision Review and returns a method not allowed status" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["message"]).to eq("Decision Review Created Error Saved in Caseflow")
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
        # Omitting Authorization header to simulate missing token
        post :decision_review_created_error
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "catches errors" do
      it "raises a RedisLockFailed Error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(Caseflow::Error::RedisLockFailed.new("Lock Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:conflict)
        expect(response.body).to eq({ message: "Lock Failure" }.to_json)
      end
      it "raises a Standard Error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(StandardError.new("Standard Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq({ message: "Standard Failure" }.to_json)
      end
    end
  end
end
